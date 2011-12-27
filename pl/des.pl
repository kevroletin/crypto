use warnings;
use strict;

use Data::Dumper::Concise;

package BitsArray;
use warnings;
use strict;

sub split_32 {
    my ($bit_array) = @_;
    die "length != 64" unless @$bit_array == 64;

    ([@$bit_array[0 .. 31]], [@$bit_array[32 .. 63]])
}

sub split_28 {
    my ($b) = @_;
    die "length != 56" unless @$b == 56;

    ([@$b[0 .. 27]], [@$b[28 .. 55]])
}

sub split_6 {
    my ($b) = @_;
    die "length != 48" unless @$b == 48;

    my $res;
    for (0 .. 47) {
        $res->[$_ / 6][$_ % 6] = $b->[$_]
    }
    $res
}

sub join_arrays {
    my @res;
    for (@_) {
        push @res, $_ for @$_
    }
    \@res
}

sub map_xor {
    my ($f, $s) = @_;
    die "different lenghts" unless @$f == @$s;
    my @res;
    for my $i (0 .. $#{$f}) {
        push @res, ($f->[$i] xor $s->[$i]) ? 1 : 0
    }
    \@res
}

sub circle_shift {
    my ($b) = @_;
    my $t = shift $b;
    push $b, $t;
    $b;
}

sub to_dec {
    my ($bin_arr) = @_;
    my $i = $#{$bin_arr};
    my $res = 0;
    my $bin_pow = 1;
    while ($i >= 0) {
        $res += $bin_arr->[$i] * $bin_pow;
        $bin_pow *= 2;
        --$i;
    }
    $res
}

sub from_dec {
    my ($dec) = @_;
    my @res;
    while ($dec) {
        unshift @res, $dec % 2;
        $dec = int ($dec / 2);
    }
    unshift @res, 0 while @res < 4;
    \@res
}

sub from_hex {
    my ($hex) = @_;
    my @res;
    my $h = { 0 => [qw(0 0 0 0)],
              1 => [qw(0 0 0 1)],
              2 => [qw(0 0 1 0)],
              3 => [qw(0 0 1 1)],
              4 => [qw(0 1 0 0)],
              5 => [qw(0 1 0 1)],
              6 => [qw(0 1 1 0)],
              7 => [qw(0 1 1 1)],
              8 => [qw(1 0 0 0)],
              9 => [qw(1 0 0 1)],
              a => [qw(1 0 1 0)],
              b => [qw(1 0 1 1)],
              c => [qw(1 1 0 0)],
              d => [qw(1 1 0 1)],
              e => [qw(1 1 1 0)],
              f => [qw(1 1 1 1)] };
    for (split //, $hex) {
        push @res, $_ for @{$h->{$_}}
    }
    \@res
}

sub to_hex {
    my ($self) = @_;
    my $b = [@{$self}];
    my $a = [0 .. 9, 'a' .. 'f'];
    my $res;
    while (@$b) {
        my @p = map { shift $b } 1 .. 4;
        $res .= $a->[to_dec(\@p)];
    }
    $res
}

sub pretty_print {
    my ($self, $len) = @_;
    $len ||= 8;
    my $j = 0;
    for (@{$self}) {
        print $_;
        print ' ' unless ++$j % $len;
    }
    print "\n";
}

1;

package Permutation;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper::Concise;

use Carp;
#$SIG{__WARN__} = sub { Carp::confess @_ };
$SIG{__DIE__} = sub { Carp::confess @_ };
#$SIG{INT} = sub { Carp::confess @_ };


subtype 'BitsArray', as 'ArrayRef[Int]',
    where {
        my $ok = 1;
        for my $val (@$_) {
            $ok &&= $val ~~ [0, 1]
        }
        $ok
    },
    message { "Contains value not in [0, 1]: " . Dumper $_ };

subtype 'Parmutatin', as 'ArrayRef[Int]',
    where {
        my %h;
        my $max = $_->[0];
        for (@$_) {
            $h{$_} = 1;
            $max = $_ if $_ > $max;
        }
        unless ($max) {
            warn "empty permutation"
        } else {
            for (1 .. $max) {
                warn "$_ unused in permutation" unless $h{$_}
            }
        }
        1
    },
    message { "" };


subtype 'IntArray', as 'ArrayRef[Int]';

has table => (isa => 'Parmutatin',
              is => 'ro',
              required => 1 );

has length => (isa => 'Maybe[Int]',
               is => 'ro');

sub execute {
    my ($self, $bits) = @_;
    find_type_constraint('ArrayRef[Int]')->check($bits)
        or die "Bad bits sequence: " . Dumper $bits;
    my $len = defined $self->length() ? $self->length() :
                                        @{$self->table()};
    @$bits == $len
        or die "Bad sequence length: " . @$bits . " != " .
            @{$self->table()};

    my $res = [];
    my $i = 0;
    for (@{$self->table()}) {
        $res->[$i++] = $bits->[$_ - 1]
    }
    $res
}

1;

package Des;
use Moose;
use Moose::Util::TypeConstraints;

subtype 'Key', as 'BitsArray',
    where { @$_ == 64 },
    message { "Bad key length" . @$_ };


has 'key' => ( isa => 'Key',
               is => 'ro',
               required => 1 );

my $init_perm = Permutation->new(table => [qw(
58 50 42 34 26 18 10 2
60 52 44 36 28 20 12 4
62 54 46 38 30 22 14 6
64 56 48 40 32 24 16 8
57 49 41 33 25 17 9  1
59 51 43 35 27 19 11 3
61 53 45 37 29 21 13 5
63 55 47 39 31 23 15 7
)]);

my $final_perm = Permutation->new(table => [qw(
40 8 48 16 56 24 64 32
39 7 47 15 55 23 63 31
38 6 46 14 54 22 62 30
37 5 45 13 53 21 61 29
36 4 44 12 52 20 60 28
35 3 43 11 51 19 59 27
34 2 42 10 50 18 58 26
33 1 41 9  49 17 57 25
)]);

my $ex_perm = Permutation->new(length => 32, table => [qw(
32 1 2 3 4 5
4 5 6 7 8 9
8 9 10 11 12 13
12 13 14 15 16 17
16 17 18 19 20 21
20 21 22 23 24 25
24 25 26 27 28 29
28 29 30 31 32 1
)]);

my $p_perm = Permutation->new(length => 32, table => [
16, 7, 20, 21, 29, 12, 28, 17,
1, 15, 23, 26, 5, 18, 31, 10,
2, 8, 24, 14, 32, 27, 3, 9,
19, 13, 30, 6, 22, 11, 4, 25
]);


my $pc_1_perm;
my $pc_2_perm;
{
    local $SIG{__WARN__} = sub {  };
    $pc_1_perm= Permutation->new(length => 64, table => [qw(
57 49 41 33 25 17 9
1  58 50 42 34 26 18
10 2  59 51 43 35 27
19 11 3  60 52 44 36
63 55 47 39 31 23 15
7  62 54 46 38 30 22
14 6  61 53 45 37 29
21 13 5  28 20 12 4
)]);

    $pc_2_perm = Permutation->new(length => 56, table => [qw(
14 17 11 24 1 5
3 28 15 6 21 10
23 19 12 4 26 8
16 7 27 20 13 2
41 52 31 37 47 55
30 40 51 45 33 48
44 49 39 56 34 53
46 42 50 36 29 32
)]);

}

my @s =
([
14 ,4 ,13 ,1 ,2 ,15 ,11 ,8 ,3 ,10 ,6 ,12 ,5 ,9 ,0 ,7 ,
0 ,15 ,7 ,4 ,14 ,2 ,13 ,1 ,10 ,6 ,12 ,11 ,9 ,5 ,3 ,8 ,
4 ,1 ,14 ,8 ,13 ,6 ,2 ,11 ,15 ,12 ,9 ,7 ,3 ,10 ,5 ,0 ,
15 ,12 ,8 ,2 ,4 ,9 ,1 ,7 ,5 ,11 ,3 ,14 ,10 ,0 ,6 ,13 ] ,
[
15 ,1 ,8 ,14 ,6 ,11 ,3 ,4 ,9 ,7 ,2 ,13 ,12 ,0 ,5 ,10 ,
3 ,13 ,4 ,7 ,15 ,2 ,8 ,14 ,12 ,0 ,1 ,10 ,6 ,9 ,11 ,5 ,
0 ,14 ,7 ,11 ,10 ,4 ,13 ,1 ,5 ,8 ,12 ,6 ,9 ,3 ,2 ,15 ,
13 ,8 ,10 ,1 ,3 ,15 ,4 ,2 ,11 ,6 ,7 ,12 ,0 ,5 ,14 ,9 ] ,
[
10 ,0 ,9 ,14 ,6 ,3 ,15 ,5 ,1 ,13 ,12 ,7 ,11 ,4 ,2 ,8 ,
13 ,7 ,0 ,9 ,3 ,4 ,6 ,10 ,2 ,8 ,5 ,14 ,12 ,11 ,15 ,1 ,
13 ,6 ,4 ,9 ,8 ,15 ,3 ,0 ,11 ,1 ,2 ,12 ,5 ,10 ,14 ,7 ,
1 ,10 ,13 ,0 ,6 ,9 ,8 ,7 ,4 ,15 ,14 ,3 ,11 ,5 ,2 ,12 ] ,
[
7 ,13 ,14 ,3 ,0 ,6 ,9 ,10 ,1 ,2 ,8 ,5 ,11 ,12 ,4 ,15 ,
13 ,8 ,11 ,5 ,6 ,15 ,0 ,3 ,4 ,7 ,2 ,12 ,1 ,10 ,14 ,9 ,
10 ,6 ,9 ,0 ,12 ,11 ,7 ,13 ,15 ,1 ,3 ,14 ,5 ,2 ,8 ,4 ,
3 ,15 ,0 ,6 ,10 ,1 ,13 ,8 ,9 ,4 ,5 ,11 ,12 ,7 ,2 ,14 ] ,
[
2 ,12 ,4 ,1 ,7 ,10 ,11 ,6 ,8 ,5 ,3 ,15 ,13 ,0 ,14 ,9 ,
14 ,11 ,2 ,12 ,4 ,7 ,13 ,1 ,5 ,0 ,15 ,10 ,3 ,9 ,8 ,6 ,
4 ,2 ,1 ,11 ,10 ,13 ,7 ,8 ,15 ,9 ,12 ,5 ,6 ,3 ,0 ,14 ,
11 ,8 ,12 ,7 ,1 ,14 ,2 ,13 ,6 ,15 ,0 ,9 ,10 ,4 ,5 ,3 ] ,
[
12 ,1 ,10 ,15 ,9 ,2 ,6 ,8 ,0 ,13 ,3 ,4 ,14 ,7 ,5 ,11 ,
10 ,15 ,4 ,2 ,7 ,12 ,9 ,5 ,6 ,1 ,13 ,14 ,0 ,11 ,3 ,8 ,
9 ,14 ,15 ,5 ,2 ,8 ,12 ,3 ,7 ,0 ,4 ,10 ,1 ,13 ,11 ,6 ,
4 ,3 ,2 ,12 ,9 ,5 ,15 ,10 ,11 ,14 ,1 ,7 ,6 ,0 ,8 ,13 ] ,
[
4 ,11 ,2 ,14 ,15 ,0 ,8 ,13 ,3 ,12 ,9 ,7 ,5 ,10 ,6 ,1 ,
13 ,0 ,11 ,7 ,4 ,9 ,1 ,10 ,14 ,3 ,5 ,12 ,2 ,15 ,8 ,6 ,
1 ,4 ,11 ,13 ,12 ,3 ,7 ,14 ,10 ,15 ,6 ,8 ,0 ,5 ,9 ,2 ,
6 ,11 ,13 ,8 ,1 ,4 ,10 ,7 ,9 ,5 ,0 ,15 ,14 ,2 ,3 ,12 ] ,
[
13 ,2 ,8 ,4 ,6 ,15 ,11 ,1 ,10 ,9 ,3 ,14 ,5 ,0 ,12 ,7 ,
1 ,15 ,13 ,8 ,10 ,3 ,7 ,4 ,12 ,5 ,6 ,11 ,0 ,14 ,9 ,2 ,
7 ,11 ,4 ,1 ,9 ,12 ,14 ,2 ,0 ,6 ,10 ,13 ,15 ,3 ,5 ,8 ,
2 ,1 ,14 ,7 ,4 ,10 ,8 ,13 ,15 ,12 ,9 ,0 ,3 ,5 ,6 ,11 ]);


my $trace = {
cd => [
[split //, qw(11110000110011001010101000001010101011001100111100000000)],
[split //, qw(11100001100110010101010000010101010110011001111000000001)],
[split //, qw(11000011001100101010100000111010101100110011110000000010)],
[split //, qw(00001100110010101010000011111010110011001111000000001010)],
[split //, qw(00110011001010101000001111001011001100111100000000101010)],
[split //, qw(11001100101010100000111100001100110011110000000010101010)],
[split //, qw(00110010101010000011110000110011001111000000001010101011)],
[split //, qw(11001010101000001111000011001100111100000000101010101100)],
[split //, qw(00101010100000111100001100110011110000000010101010110011)],
[split //, qw(01010101000001111000011001100111100000000101010101100110)],
[split //, qw(01010100000111100001100110011110000000010101010110011001)],
[split //, qw(01010000011110000110011001011000000001010101011001100111)],
[split //, qw(01000001111000011001100101010000000101010101100110011110)],
[split //, qw(00000111100001100110010101010000010101010110011001111000)],
[split //, qw(00011110000110011001010101000001010101011001100111100000)],
[split //, qw(01111000011001100101010100000101010101100110011110000000)],
[split //, qw(11110000110011001010101000001010101011001100111100000000)]],
key => [
[],
[ split //, qw(000010110000001001100111100110110100100110100101)],
[ split //, qw(011010011010011001011001001001010110101000100110)],
[ split //, qw(010001011101010010001010101101000010100011010010)],
[ split //, qw(011100101000100111010010101001011000001001010111)],
[ split //, qw(001111001110100000000011000101111010011011000010)],
[ split //, qw(001000110010010100011110001111001000010101000101)],
[ split //, qw(011011000000010010010101000010101110010011000110)],
[ split //, qw(010101111000100000111000011011001110010110000001)],
[ split //, qw(110000001100100111101001001001101011100000111001)],
[ split //, qw(100100011110001100000111011000110001110101110010)],
[ split //, qw(001000010001111110000011000011011000100100111010)],
[ split //, qw(011100010011000011100101010001010101110001010100)],
[ split //, qw(100100011100010011010000010010011000000011111100)],
[ split //, qw(010101000100001110110110100000011101110010001101)],
[ split //, qw(101101101001000100000101000010100001011010110101)],
[ split //, qw(110010100011110100000011101110000111000000110010)] ]
};


#sub _reduced_key {
#    my ($self) = @_;
#    my @res;
#    my $i = 0;
#    for (@{$self->key()}) {
#        next unless ++$i % 8;
#        push @res, $_
#    }
#    \@res;
#}


sub _select_s {
    my ($self, $s_num, $bit_arr) = @_;
    die "should be 6-bit" unless @$bit_arr == 6;
    my $b = [@{$bit_arr}];
    my $t = shift $b;
    my $p = pop $b;
    unshift $b, $p;
    unshift $b, $t;

    my $n = BitsArray::to_dec($b);
    my $res =  BitsArray::from_dec( $s[$s_num][$n] );
#    print "s-block $s_num:\n";
#    print "               from " . (join '', @$bit_arr);
#    print "\n               to   " . (join '', @$res);
#    print "\n";

    $res;
}

sub _f {
    my ($self, $round_key, $data) = @_;
    my $ex_d = $ex_perm->execute($data);
    print "ex_data:", BitsArray::to_hex($ex_d), "\n";
    BitsArray::pretty_print($ex_d, 6);
    my $t_res = BitsArray::map_xor($ex_d, $round_key);

#    print "xor:\n";
#    BitsArray::pretty_print($t_res, 6);

    my $s_block_data = BitsArray::split_6($t_res);
    my @s_block_res;
    for my $s_block_num (0 .. 7) {
        my $t = $self->_select_s($s_block_num,
                                 $s_block_data->[$s_block_num]);
        push @s_block_res, $t;
    }

#    BitsArray::pretty_print(BitsArray::join_arrays(@s_block_res), 4);
    $p_perm->execute(BitsArray::join_arrays(@s_block_res));
}

sub process_block {
    my ($self, $data) = @_;
    die "bad block length" unless @$data == 64;

    my ($a_0, $b_0) = BitsArray::split_32(
                          $init_perm->execute($data)
                      );

    print "Ip: ";
    print BitsArray::to_hex($init_perm->execute($data));
    print "\n";


    my $ext_key = $pc_1_perm->execute($self->key());

    my ($c, $d) = BitsArray::split_28($ext_key);
    for my $round (1 .. 16) {
        print "===Round $round===\n";

        print "A_i:\n";
        BitsArray::pretty_print($a_0, 7);
        print "B_i:\n";
        BitsArray::pretty_print($b_0, 7);

#        print "before shift:\n";
#        BitsArray::pretty_print(BitsArray::join_arrays($c, $d));
        for (($round ~~ [1, 2, 9, 16]) ? 1 : (1, 2)) {
            BitsArray::circle_shift($c);
            BitsArray::circle_shift($d);
        }
#        print "after shift:\n";
#        BitsArray::pretty_print(BitsArray::join_arrays($c, $d));
        die $round unless
            BitsArray::join_arrays($c, $d) ~~ $trace->{cd}[$round];
        my $t_key = BitsArray::join_arrays($c, $d);

        my $subkey = $pc_2_perm->execute($t_key);
        print "key:", BitsArray::to_hex($t_key), "\n";
        BitsArray::pretty_print($subkey, 6);
        unless ($subkey ~~ $trace->{key}[$round]) {
            print "should be:\n";
#            print Dumper( $trace->{key}[$round] );
            print BitsArray::to_hex($trace->{key}[$round]), "\n";
            print BitsArray::pretty_print($trace->{key}[$round]);
            #            die "bad key"
            exit();
        }

        my $f_res = $self->_f($subkey, $b_0);

        print "p:\n";
        BitsArray::pretty_print($f_res);
        ($a_0 , $b_0) = ($b_0,
                         BitsArray::map_xor($f_res, $a_0));
    }
    ($a_0 , $b_0) = ($b_0, $a_0);
    my $res = BitsArray::join_arrays($a_0, $b_0);

    $final_perm->execute($res)
}

1;

use Data::Dumper::Concise;

#my $key = [map { $_ > 31 ? 1 : 0 } 0 .. 63];
#my $key = BitsArray::from_hex(lc('0123456789ABCDEF'));
#my $key = BitsArray::from_hex(lc('5b5a57676a56676e'));
my $encoder = Des->new(key => $key);
#my $data = [map { $_ > 31 ? 1 : 0 } 0 .. 63];
#my $data = BitsArray::from_hex(lc('4E6F772069732074'));
#my $data = BitsArray::from_hex(lc('675a69675e5a6b5a'));

print Dumper( Des::_select_s(undef, 1, [split //, '110001']));
#               from 110001
#               to   1101


#exit;

my $res = $encoder->process_block($data);
#print Dumper $res;

#key: print '00000001 00100011 01000101 01100111 10001001 10101011 11001101 11101111';

print BitsArray::to_hex($res);

#print Des::_select_s(undef, 

exit();

#my $a = [1, 2, 3];
#BitsArray::circle_shift($a);
#BitsArray::circle_shift($a);
#print Dumper( $a );

__END__

for my $j (0 .. 7) {
    for my $i (0 .. 3) {
        print $a[$i*8 + $j], ' ';
    }
    print "\n"
}


