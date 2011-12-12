use warnings;
use strict;
use List::Util 'reduce';

use Data::Dumper::Concise;

sub table {
    my $j = 0;
    my $alph = ['A' .. 'Z'];
    my ($rows, $cols, $rows_sym_pos, $cols_sym_pos);
    for my $i (0 .. 25 ) {
        $cols_sym_pos->{$alph->[$i]} = $i;
    }
    for my $j (0 .. 25) {
        my ($t, $h);
        for my $i (0 .. 25) {
            my $sym = $alph->[($i + $j) % 26];
            $rows->[$j]->{array}->[$i] = $sym;
            $rows->[$j]->{hash}{$sym} = $i;
            $cols->[$i]->{array}->[$j] = $sym;
            $cols->[$i]->{hash}{$sym} = $j;
        }
        $rows_sym_pos->{$alph->[$j]} = $j;
    }
    { rows => $rows,
      cols => $cols,
      rows_sym_pos => $rows_sym_pos,
      rows_pos_sym => ['A' .. 'Z'],
      cols_sym_pos => $cols_sym_pos,
      cols_pos_sym => ['A' .. 'Z'] }
}

sub encode_symbol {
    my ($table, $key_sym, $sym) = @_;
    my $row = $table->{rows_sym_pos}{$sym};
    my $col = $table->{cols_sym_pos}{$key_sym};
    $table->{rows}->[$row]->{array}->[$col];
}

sub decode_symbol {
    my ($table, $key_sym, $sym) = @_;
    my $row = $table->{cols_sym_pos}{$key_sym};
    my $col = $table->{rows}->[$row]->{hash}{$sym};
    $row = $table->{cols}->[$col]->{hash}{$sym};
    $table->{rows_pos_sym}->[$row];
}

sub apply_circulary {
    my ($key, $text, $sub) = @_;
    my $table = table();
    my @a = split //, $key;
    my $i = 0;
    my $proc = sub {
        my $res = $sub->($table, $a[$i], $_[0]);
        $i = ($i + 1) % @a;
        $res
    };
    join '', map { $proc->($_) } split //, $text
}

sub encode {
    my ($key, $text) = @_;
    apply_circulary($key, $text, \&encode_symbol)
}

sub decode {
    my ($key, $text) = @_;
    apply_circulary($key, $text, \&decode_symbol)
}

=begin

my $key = 'CRYPTO';
my $text = 'PURPLEPURPLE';
my $res = encode($key, $text);
print "$res\n";
print  decode($key, $res);

=cut

sub analize_periods {
    my ($periods) = @_;
    my %periods;
    for (keys %$periods) {
        my ($pattern, $positions) = ($_, $periods->{$_});
        my $scores = length($pattern) + @$positions;
        for my $i (1 .. $#{$positions}) {
            my $period = $positions->[$i] - $positions->[$i - 1];
            $periods{$period} ||= 0;
            $periods{$period} += $scores;
        }
    }
    my $ans = reduce { $periods{$a} > $periods{$b} ? $a : $b }
        keys %periods;
    my @rating = sort { $periods{$a} <=> $periods{$b} }
        keys %periods;
    ($ans, \@rating);
}

sub find_period {
    my ($text) = @_;
    my %res;
    for my $p_len (1 .. length($text) - 1) {
        for my $i (0 .. length($text) - $p_len) {
            my $pattern = substr($text, $i, $p_len);
            next if $res{$pattern};
            $res{$pattern} ||= [];
            while ($text =~ m/$pattern/g) {
                push @{$res{$pattern}}, pos($text)
            }
        }
    }
    my ($ans, $rating) = analize_periods(\%res);
    $ans
}


my $text = <<TEXT
AVXZHHCKALBRVIGLGMOSTHBWMSXSPELHHLLABABKVXHIGHPNPRALFXAVBUPNPZWVCLTOESCGLGBMHKHPELHBWZXVTLACFJOGUCGSSLZWMZHBUURDSBZHALVXHFMVMOFHDKTASKVBPFULQHTSLTCKGAVHMLFRVITYILFBLBVLPHAVHHBUGTBBTAVXZWPBZPGGVHWPXTCLAQHTAHUAPBZHGTBBTPGMOLACOLKBAVMVALGMVJXPGHUZUMFLHTSPHEKBCGLGHUHHWHALMISALOMLRIYCPGOLFRZATSZGWMOHALVXHFMVTLHIMOSLLVNTSMOIWYMTHFMVGVBGBZHTVVTCCYLKRHABAVTJBMOSILFELJXYTLHIGHACWWLHURTLLLRSSMLAZSCNKVFIPXGH
TEXT
;

print find_period('ababab');
print find_period('zabcabc435');


#my $text = 'abczabczz';

#my ($ans) = find_period("ababab");
#print Dumper $ans;
#chomp($text);
#print $text;

