use warnings;
use strict;
use feature "switch";

sub parse {
    my ($str) = @_;
    my @res;
    my @a = split /[\s\+\(\)]/, $str;
    my @pair;
    while (@a) {
        $_ = shift @a;
        my $not = 0;
        given ($_) {
            when ('not') {
                $not = 1;
                $_ = shift @a;
                continue
            }
            when (/\w/) {
                push @pair, {char => $_, not => $not}
            }
        }
        if (@pair >= 2) {
            push @res, [@pair];
            @pair = ();
        }
    }
    \@res
}

sub solve {
    my ($expr, $i, $val) = @_;
    return 1 unless defined $expr->[$i];

    my $p = $expr->[$i];
    my $a = $p->[0]{char};
    my $not_a = $p->[0]{not};
    my $b = $p->[1]{char};
    my $not_b = $p->[1]{not};

    my @v;
    my ($last_a, $last_b) = ($val->{$a}, $val->{$b});
    if (!defined $val->{$a} && !defined $val->{$b}) {
        @v = ([1, 0],[0, 1],[1, 1],[0, 0]);
    } elsif (!defined $val->{$a}) {
        @v = ([1, $val->{$b}],[0, $val->{$b}]);
    } elsif (!defined $val->{$b}) {
        @v = ([1, $val->{$a}],[0, $val->{$a}]);
    } else {
        @v = ([$val->{$a}, $val->{$b}]);
    }

    for (@v) {
        ($val->{$a}, $val->{$b}) = @$_;
        next unless ($val->{$a} xor $not_a) ||
                    ($val->{$b} xor $not_b);
        my $res = solve($expr, $i+1, $val);
        return 1 if $res;
    }

    ($val->{$a}, $val->{$b}) = ($last_a, $last_b);
    return 0;
}

my $str = '(a + b)(not a + b)(a + not b)(not a + not b)';
print solve(parse($str), 0, {});

$str = '(a + b)(not a + b)(a + not b)';
print solve(parse($str), 0, {});
