# DbgrProperties.pm -- Move all the property-handling code
# into this module.
#
# Copyright (c) 1998-2006 ActiveState Software Inc.
# All rights reserved.
# 
# Xdebug compatibility, UNIX domain socket support and misc fixes
# by Mattia Barbon <mattia@barbon.org>
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::DbgrProperties;

use strict qw(vars subs);

our $VERSION = 0.10;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	     doPropertySetInfo
	     emitContextNames
	     emitContextProperties
	     emitEvalResultAsProperty
	     emitEvaluatedPropertyGetInfo
	     figureEncoding
	     getContextProperties
	     getFullPropertyInfoByValue
	     getPropertyInfo
	     GlobalVars
	     LocalVars
	     FunctionArguments
	     PunctuationVariables
	     );
our @EXPORT_OK = ();

use overload;

use DB::Data::Dump;
use DB::DbgrCommon;

# Internal sub declarations

sub adjustLongName($$$);
sub makeFullName($$);

# And recursively-called exported routines:

sub figureEncoding($);
sub getFullPropertyInfoByValue($$$$$$);

# Constants

use constant LocalVars => 0;
use constant GlobalVars => 1;
use constant FunctionArguments => 2;
use constant PunctuationVariables => 3;

our $ldebug = 0;

# Private Data

my %contextProperties = (
    Globals => GlobalVars,
    Locals => LocalVars,
    Arguments => FunctionArguments,
    Special => PunctuationVariables,
);
my @contextProperties = sort { $contextProperties{$a} <=> $contextProperties{$b} } keys %contextProperties;

my @_punctuationVariables = ('$_', '$?', '$@', '$.', '@+', '@-', '$+', '$!', '$$', '$0');
# $`, $& and $' are special-cased to avoid the performance penalty
my @_rxPunctuationVariables = ('`', '&', '\'');

# Exported subs

=head1 postconditions

This function does one of three things:

1. Throw an exception: let the caller deal with it, and formulate
an error message.

2. Assign a value to a local value if it's a non-top-level stack
Return undef

3. Return [$property_long_name, undef, 1]
and let the caller do an eval to carry out the assignment.

=cut

sub doPropertySetInfo($$$) {
    my ($cmd,
	$transactionID,
	$property_long_name) = @_;
    
    if (!defined $property_long_name) {
	return makeErrorResponse($cmd,
				 $transactionID,
				 DBP_E_InvalidOption,
				 "-n full-property-name missing");
    } else {
	# In Perl these can be modified.  Setting $_[x] to a value
	# changes the underlying object if it isn't constant.
	# Other changes will be ignored.
	return [$property_long_name, undef, 1];
    }
}

sub emitContextNames($$) {
    my ($cmd, $transactionID) = @_;
    my $res = sprintf(qq(%s\n<response %s command="%s" 
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $transactionID);
    # todo: the spec suggests that locals be the default,
    # but globals (package globals) make more sense for Perl.
    for (my $i = 0; $i <= $#contextProperties; $i++) {
	$res .= sprintf(qq(<context name="%s" id="%d" />\n),
			$contextProperties[$i],
			$i);
    }
    $res .= "\n</response>\n";
    printWithLength($res);
}

sub emitContextProperties($$$$;$) {
    my ($cmd,
	$transactionID,
	$context_id,
	$nameValuesARef,
	$maxDataSize) = @_;
    
    my $res = sprintf(qq(%s\n<response %s command="%s"
			 context_id="%d"
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $context_id,
		      $transactionID);
    my @results = @$nameValuesARef;
    my $numVars = scalar @results;
    for (my $i = 0; $i < $numVars; $i++) {
	my $result = $results[$i];
	my $name = $result->[0];
	my $val = $result->[1];
	eval {
	    my $property = getFullPropertyInfoByValue($name,
						      $name,
						      $val,
						      $maxDataSize,
						      0,
						      0);
	    # dblog("emitContextProperties: getFullPropertyInfoByValue => $property") if $ldebug;
	    $res .= $property;
	};
	if ($@) {
	    dblog("emitContextProperties: error [$@]") if $ldebug;
	}
    }
    $res .= "\n</response>";
    printWithLength($res);
}


sub emitEvaluatedPropertyGetInfo($$$$$$$) {
    my ($cmd,
	$transactionID,
	$nameAndValue,
	$property_long_name, # For the response things.
	$propertyKey,
	$maxDataSize,
	$pageIndex) = @_;

    my $res = sprintf(qq(%s\n<response %s command="%s" 
			 transaction_id="%s" ),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $transactionID);
    my $finalVal = $nameAndValue->[NV_VALUE];

    $res .= '>' if $cmd ne 'property_value';
    my $startTag = $cmd ne 'property_value' ? '<property' : '';
    my $endTag = $cmd ne 'property_value' ? '</property>' : '';
    my $finalName = makeFullName($property_long_name, $propertyKey);
    $res .= _getFullPropertyInfoByValue($startTag, $endTag,
					$propertyKey || $finalName, # name
					$finalName,
					$finalVal,
					$maxDataSize,
					$pageIndex, # page
					0, # current depth
					);
    $res .= "\n</response>";
    printWithLength($res);
}

# Return a ref to an array of [name, value, needValue] triples
#
# Some values can be evaluated in this scope, but non-package values
# and locals at the top-level will need to be evaluated in the
# debugger's main loop.

sub getContextProperties($$) {
    my ($context_id, $packageName) = @_;

    # Here just show the top-level.
    local $settings{max_depth}[0] = 0;
    if ($context_id == GlobalVars) {
	require B if $] >= 5.010;
	# Globals
	# Variables on the calling frame
	my $stash = \%{"${packageName}::"};
	my @results;
	for my $key (keys %$stash) {
	    next if $key =~ /^(?:_<|[^0a-zA-Z_])/;
	    next if $key =~ /::$/;
	    my $glob = \($stash->{$key});
	    my ($has_scalar, $is_glob);
	    if ($] >= 5.010) {
		my $gv = B::svref_2object($glob);
		$is_glob = $gv->isa("B::GV");
		$has_scalar = $is_glob && !$gv->SV->isa('B::SPECIAL');
	    } else {
		$is_glob = 1;
		$has_scalar = defined ${*{$glob}{SCALAR}};
	    }
	    my $array = $is_glob && *{$glob}{ARRAY};
	    my $hash = $is_glob && *{$glob}{HASH};
	    next unless $has_scalar || $array || $hash;
	    push @results, ["\$${key}", ${*{$glob}{SCALAR}}, 0] if $has_scalar;
	    push @results, ["\@${key}", $array, 0] if $array;
	    push @results, ["\%${key}", $hash, 0] if $hash;
	}
	return \@results;
    } elsif ($context_id == PunctuationVariables) {
	my ($packageName, $filename, $line) = caller(1);
	my %vals;
	my @results;
	foreach my $pv (@_punctuationVariables) {
	    push (@results, [$pv, undef, 1]);
	}
	foreach my $pv (@_rxPunctuationVariables) {
	    # somebody might use @' and trigger the condition, I'm willing to risk it
	    push (@results, ["\$$pv", undef, exists $main::{$pv} ? 1 : 0]);
	}
	return \@results;
	
    } else {
	die sprintf("code:%d:error:%s",
		    302,
		    ("Not ready to evaluate "
		     . $contextProperties[$context_id]
		     . ' variables'));
    }
}
 
sub _truncateIfNecessary {
    my($res, $maxDataSize, $stripOuterBrackets) = @_;
    if ($stripOuterBrackets && $res =~ /^([\[\{\(\<]).*([\]\}\)\>])$/) {
	substr($res, 0, 1) = "";
	substr($res, -1, 1) = "";
    }
    # Truncate if exceeds size
    if ($maxDataSize > 0) {
	$maxDataSize -= 2 if $stripOuterBrackets;
	if (length($res) > $maxDataSize) {
	    dblog("_truncateIfNecessary: Have length(\$res) = ", length($res), " > $maxDataSize") if $ldebug;
	    if ($maxDataSize >= 3) {
		$res = substr($res, 0, ($maxDataSize - 3)) . "...";
	    } else {
		$res = substr($res, 0, $maxDataSize);
	    }
	    dblog("_truncateIfNecessary: After: length(\$res) = ", length($res)) if $ldebug;
	}
    }
    return $res;
}

sub emitEvalResultAsProperty($$$$$$) {
    my ($cmd,
	$transactionID,
	$property_long_name,
	$valRefs,
	$maxDataSize,
	$pageIndex) = @_;
    my $res = sprintf(qq(%s\n<response %s command="%s" 
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $transactionID);
    $res .= getFullPropertyInfoByValue($property_long_name, # name
				       $property_long_name,
				       $valRefs,
				       $maxDataSize,
				       $pageIndex,
				       0, # current depth
				       );
    $res .= "\n</response>";
    printWithLength($res);
}

sub getPropertyInfo($$) {
    my ($property_long_name, $propertyKey) = @_;

    # Invariant: FunctionArguments are handled by the caller.
    
    my $finalName = makeFullName($property_long_name, $propertyKey);
    return [$finalName, undef, 1];
}
   
sub propertyTagSpacer($) {
    my ($currentDepth) = @_;
    return ("\n" . ('  ' x $currentDepth));
}

sub containsWideChar {
    my ($str) = @_;
    require bytes;
    if (bytes::length($str) > length($str)
	|| $str =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]/
	|| $str =~ /[^\0-\xff]/) {
	return 1;
    }
    return 0;
}
    
sub figureEncoding($) {
    my ($val) = @_;
    my ($encVal);
    my $encoding = $settings{data_encoding}->[0];
    my $hasWide = containsWideChar($val);
    if ($encoding eq 'none' || $encoding eq 'binary') {
	if ($val =~ m/[\x00-\x08\x0b\x0c\x0e-\x1f]/) {
	    # Override
	    $encoding = 'base64';
	}
    }
    if ($hasWide && $encoding eq 'base64') {
	$val = nonXmlChar_Encode($val);
    }
    $encVal = encodeData($val, $encoding);
    if ($encoding eq 'none' || $encoding eq 'binary') {
	$encVal = xmlEncode($encVal);
    }
    return ($encoding, $encVal);
}

sub _attr_needs_base64_encoding {
    my ($val) = @_;
    return ($val =~ /[^\x20-\x7f]/);
}

sub getFullPropertyInfoByValue($$$$$$) {
    _getFullPropertyInfoByValue('<property', '</property>', @_);
}

sub _getFullPropertyInfoByValue {
    my ($startTag,
	$endTag,
	$name,
	$fullname,
	$val,
	$maxDataSize,
	$pageIndex,
	$currentDepth,
	) = @_;
    # dblog("getFullPropertyInfoByValue: (@_)\n");
    my $encoding;
    my $res = $startTag;
    if ($currentDepth > 0) {
	$res .= propertyTagSpacer($currentDepth);
    }
    my %b_attr = (name => $name, fullname => $fullname);
    my %b_needs_attr;
    $b_needs_attr{name} = _attr_needs_base64_encoding($name);
    $b_needs_attr{fullname} = _attr_needs_base64_encoding($fullname);
    while (my($k, $v) = each %b_needs_attr) {
	if (!$v) {
	    $res .= sprintf(qq( $k="%s"), xmlAttrEncode($b_attr{$k}));
	    delete $b_attr{$k};
	}
    }
    my $typeString;
    my $hasChildren = 0;
    my $numChildren;
    my $className;
    my ($h1, $h2) = split(//, $fullname, 2);
    my $encVal = undef;
    my $encValLength = undef;
    my $refstr = "";
    my $address;
    my $variableGroup = -1;
    use constant VARIABLE_GROUP_ARRAY => 1;
    use constant VARIABLE_GROUP_HASH => 2;
    if (!defined $val) {
	$typeString = 'undef';
    } else {
	# Unlike getPropertyInfo, this is where we find
	# arrays and hashes
	if ($refstr = ref $val) {
	    my $stringifiedVal = "" . $val;
	    if ($refstr =~ /^ARRAY/) {
		$typeString = $refstr;
		$variableGroup = VARIABLE_GROUP_ARRAY;
		$numChildren = scalar @$val;
		$hasChildren = $numChildren >= 1;
		($address) = ($stringifiedVal =~ m/^ARRAY\(0x(.*)\)$/i);
	    } elsif ($refstr =~ /^HASH/) {
		$typeString = $refstr;
		$variableGroup = VARIABLE_GROUP_HASH;
		$numChildren = scalar keys %$val;
		$hasChildren = $numChildren >= 1;
		($address) = ($stringifiedVal =~ m/^HASH\(0x(.*)\)$/i);
	    } elsif ($refstr =~ /^Regexp/) {
		# Special-case -- only one in Perl?
		$typeString = 'Regexp';
		$numChildren = 0;
		$hasChildren = 0;
		$val = substr("$val", 0, $maxDataSize);
		($encoding, $encVal) = figureEncoding($val);
		$res .= sprintf(qq( encoding="%s"), $encoding);
		$encValLength = length($encVal);
		$refstr = undef;
	    } else {
		my $overloadedRefStr;
		($typeString, $numChildren, $className, $overloadedRefStr) = analyzeVal($val);
		if ($overloadedRefStr) {
		    $refstr = $overloadedRefStr;
		}
		$hasChildren = $numChildren && 1;
		if ($className) {
		    $typeString = $className;
		    if ($maxDataSize >= 0 && length($val) > $maxDataSize) {
			# dblog("getFullPropertyInfoByValue: truncating data down to $maxDataSize bytes:\n[$val]\n");
			$val = substr($val, 0, $maxDataSize);
		    }
		    ($encoding, $encVal) = figureEncoding($val);
		    $res .= sprintf(qq( encoding="%s"), $encoding);
		    $encValLength = length($encVal);
		} else {
		    ($address) = ($stringifiedVal =~ m/^.+\(0x(.*)\)$/i);
		}
	    }
	} else {
	    $hasChildren = 0;
	    # It's a scalar -- get the underlying value and classify.
	    # First convert wide chars to utf-8
	    my $val2 = nonXmlChar_Encode($val);
	    my $val3 = _truncateIfNecessary($val2, $maxDataSize, 0);
	    ($encoding, $encVal) = figureEncoding($val3);
	    $res .= sprintf(qq( encoding="%s"), $encoding);
	    $encValLength = length($encVal);
	    $typeString = getCommonType($val2);
	}
    }
    $res .= sprintf(qq( type="%s"), xmlAttrEncode($typeString));
    $res .= qq( constant="0");
    if ($hasChildren) {
	$res .= qq( children="1" numchildren="$numChildren");
	if (defined $address) {
	    $res .= qq( address="$address");
	}
    } else {
	$res .= qq( children="0");
    }

    if ($hasChildren) {
	$res .= qq( size="0");
	$res .= qq( page="$pageIndex");
	$res .= sprintf(qq( pagesize="%d"), $settings{max_children}[0]);
	# Get each child property
	if ($currentDepth < $settings{max_depth}[0]) {
	    my $childrenPerPage = $settings{max_children}[0];
	    my $startIndex = $pageIndex * $childrenPerPage;
	    my $endIndex = $startIndex + $childrenPerPage - 1;
	    if ($variableGroup == VARIABLE_GROUP_ARRAY
		|| $refstr =~ /=ARRAY\(0x.*\)/
		|| "$val" =~ /=ARRAY\(0x.*\)/) {
		my $arraySize = scalar @$val;
		#### ???? $res .= sprintf(qq( numchildren="%d"), $arraySize);
		$res .= qq(>);
		$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
		if ($startIndex < $arraySize) {
		    if ($endIndex >= $arraySize) {
			$endIndex = $arraySize - 1;
		    }
		    for (my $i = $startIndex; $i <= $endIndex; $i++) {
			my ($newInnerName, $newFullName) =
			    adjustLongName($fullname, $i, 1);
			my $innerProp =
			    getFullPropertyInfoByValue($newInnerName,
						       $newFullName,
						       $val->[$i],
						       $maxDataSize,
						       # For inner children,
						       # show first page
						       0,
						       $currentDepth + 1);
			$res .= "$innerProp";
		    }
		}
	    } elsif ($variableGroup == VARIABLE_GROUP_HASH
		     || $refstr =~ /=HASH\(0x.*\)/
		     || "$val" =~ /=HASH\(0x.*\)/) {
		my %hval = %$val;
		my @keys = sort keys %hval;
		my $arraySize = scalar @keys;
		#### ???? $res .= sprintf(qq( numchildren="%d"), $arraySize);
		$res .= qq(>);
		$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
		if ($startIndex < $arraySize) {
		    if ($endIndex >= $arraySize) {
			$endIndex = $arraySize - 1;
		    }
		    for (my $i = $startIndex; $i <= $endIndex; $i++) {
			my $k = $keys[$i];
			my ($newInnerName, $newFullName) =
			    adjustLongName($fullname, $k, 0);
			my $innerProp =
			    getFullPropertyInfoByValue($newInnerName,
						       $newFullName,
						       $val->{$k},
						       $maxDataSize,
						       # For inner children,
						       # show first page
						       0,
						       $currentDepth + 1);
			$res .= "$innerProp";
		    }
		}
	    } else {
		# Objects just have one child
		#### $res .= qq( numchildren="1");
		$res .= qq(>);
		$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
		my $innerProp =
		    getFullPropertyInfoByValue("->",
					       "\${$fullname}",
					       $$val,
					       $maxDataSize,
					       # For inner children,
					       # show first page
					       0,
					       $currentDepth + 1);
		$res .= "$innerProp";
	    }
	} else {
	    # End the start-tag.
	    $res .= qq( >);
	    $res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
	}
	$res .= $endTag . qq(\n);
    } else {
	$res .= qq( size="$encValLength") if defined $encValLength;
	$res .= qq( >);
	$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
	if ($refstr || !defined($encVal)) {
	    # Do nothing
	} elsif ($DB::xdebug_no_value_tag) {
	    $res .= $encVal;
	} else {
	    $res .= sprintf(qq(<value%s><![CDATA[%s]]></value>\n),
			    $encoding ? qq( encoding="$encoding") : "",
			    $encVal);
	}
	$res .= $endTag;
	$res .= "\n" if $currentDepth == 0;
    }
    # dblog("getFullPropertyInfoByValue: \{$res}\n");
    return $res;
}

sub _getFullPropertyInfoByValue_emitNames {
    my ($maxDataSize, %b_attr) = @_;
    my $ret = "";
    while (my ($k, $v) = each %b_attr) {
	my $val2 = nonXmlChar_Encode($v);
	my $val3 = _truncateIfNecessary($val2, $maxDataSize, 0);
	$ret .= (qq(<$k encoding="base64">)
		 . xmlAttrEncode(encodeData($val3, 'base64'))
		 . "</$k>\n");
    }
    return $ret;
}

# Called only by wrapVars, so it does no expansion
# It's only used to provide info on the variables for 
# a given context

sub analyzeVal($) {
    my ($val) = @_;
    if (!defined $val) {
	return ('null', 0, undef);
    } elsif (!(ref $val)) {
	return ('null', 0, undef);
    }
    my $refstr = ref $val;
    if ($refstr =~ /^ARRAY/) {
	return ($refstr, scalar @$val, undef);
    } elsif ($refstr =~ /^HASH/) {
	return ($refstr, scalar keys %$val, undef);
    } elsif ($refstr =~ /^REF/ || $refstr =~ /^SCALAR/) {
	return ($refstr, 1, undef);
    } elsif ($refstr =~ /^CODE/) {
	return ('CODE', 0, undef);
    } elsif ("$val" =~ /$refstr=/) {
	my $strVal = "$val";
        my $typeString = $refstr;
        $typeString =~ s/\(0x\w+\)//;
	if ($strVal =~ /=HASH\(0x\w+\)/) {
	    return ($typeString, scalar keys %$val, $refstr);
	} elsif ($strVal =~ /=ARRAY\(0x\w+\)/) {
	    return ($typeString, scalar @$val, $refstr);
	} else {
	    return ($typeString, 0, $refstr);
	}
    } elsif (overload::Overloaded($val)) {
	my $overloadedRefStr;
	if ($overloadedRefStr = overload::StrVal($val)) {
	    dblog('qqq:analyzeVal ' . __LINE__) if $ldebug;
	    dblog("analyzeVal -- overloaded [$val] => $overloadedRefStr") if $ldebug;
	    my $className;
	    if ($overloadedRefStr =~ /^(.*)=/) {
		$className = $1;
		dblog("  \$className = $className, \$overloadedRefStr = $overloadedRefStr") if $ldebug;
		if ($overloadedRefStr =~ /=HASH\(0x\w+\)/) {
		    return ('HASH', scalar keys %$val, $className, $overloadedRefStr);
		} elsif ($overloadedRefStr =~ /=ARRAY\(0x\w+\)/) {
		    return ('ARRAY', scalar @$val, $className, $overloadedRefStr);
		} else {
		    return ('SCALAR', 0, $className, $overloadedRefStr);
		}
	    }
	    dblog("Could pull className out of refstr [$overloadedRefStr]") if $ldebug;
	}
	# It's some other kind of bizarre overloaded operator.
	dblog('qqq:analyzeVal ' . __LINE__) if $ldebug;
	return ('SCALAR', 0, $overloadedRefStr);
    } else {
	# Return whatever it is.
	$refstr =~ s/=.*//;
	return ($refstr, 1, undef);
    }
}

#############################################################################

# Internal subs

sub adjustLongName($$$) {
    my ($fullname, $key, $isArray) = @_;
    if ($isArray) {
	if ($fullname =~ m/^(\@)(.*)/) {
	    return ("[$key]", sprintf('$%s[%d]', $2, $key));
	} else {
	    return ("->[$key]", "${fullname}->[$key]");
	}
    } else {
        # Don't use Data::Dump for hash keys, as it's doing too
        # much processing on hash keys.
        # Data::Dump was used to fix bugs 79892, 79894, and 79895 in r22847.
        # However Data::Dump \x-encodes high-bit characters,
        # which makes them hard to read in the UI, so we need to do
        # our own encoding.
        # This change fixes bug 83959
	if ($key =~ /^-?[a-zA-Z_]\w*$/) {
	    # Don't quote barewords
	} elsif ($key =~ /^-?[1-9]\d{0,8}$/ || $key eq "0") {
            # Don't quote integers
        } else {
            # Convert low-byte values, leave high-byte values alone,
            # and backslash-escape the usual suspects.
            $key =~ s{([\\\"\$\@\*\%])}
                     {\\$1}g;
            $key =~ s{([\x00-\x08\x0b\x0c\x0e-\x1f])}
                     {sprintf('\\x%02x', hex(ord($1)))}egx;
            $key =~ s{\t}{\\t}gx;
            $key =~ s{\r}{\\r}gx;
            $key =~ s{\n}{\\n}gx;
            $key = '"' . $key . '"';
	}
	if ($fullname =~ m/^(\%)(.*)/) {
	    # Verify that single-quotes won't nest.
	    return ("{$key}", sprintf(q($%s{%s}), $2, $key));
	} else {
	    return ("->{$key}", "${fullname}->{$key}");
	}
    }
}

sub makeFullName($$) {
    my ($property_long_name, $propertyKey) = @_;
    if (!$propertyKey) {
	return $property_long_name;
    } elsif ($property_long_name =~ /^[\@\%](.*)/) {
	return sprintf(q($%s%s), $1, $propertyKey);
    } else {
	return sprintf(q(%s->%s), $property_long_name, $propertyKey);
    }
}

1;
