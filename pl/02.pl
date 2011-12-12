use warnings;
use strict;
use List::Util 'sum';

=begin

sub brutforce {
    my @a = 'a' .. 'z';
    my $i = 0;
    my %h = (map { $_ => $i++ } 'a' .. 'z');
    my $s = 'ymjkw jvzjs hdrjy mtisj jixqt slhnu mjwyj cyxyt btwp';
    for my $k (0 .. 26) {
        print "$k:\n";
        for (split //, $s) {
            if (/\s/) {
                #           print $_
            } else {
                print $a[ ($h{$_} + $k) % 26 ]
            }
        }
        print "\n"
    }
}

=cut

sub split_to_groups {
    my ($text, $len) = @_;
    $len ||= 1;
    my @a = split //, $text;
    my @res;
    my $i = 0;
    while ($i < @a) {
        my @t;
        for (1 .. $len) {
            push @t, $a[$i++];
            last if $i == @a
        }
        push @res, join '', @t;
    }
    \@res
}

sub occurrence_freq {
    my ($text, $len) = @_;
    my %h;
    for (@{split_to_groups($text, $len)}) {
        $h{$_} = 0 unless defined $h{$_};
        ++$h{$_};
    }
    \%h
}

sub statistics {
    my ($text, $len, $min_cnt) = @_;
    my $res = occurrence_freq($text, $len);
    my $sum = sum values %$res;
    my @pairs = map { [$_, $res->{$_}, $res->{$_} * 100 / $sum] }
        grep { $res->{$_} >= $min_cnt } keys %$res;
    for (sort { $b->[1] <=> $a->[1] } @pairs) {
        printf "%s: %5.d   - %.2f %%\n", @{$_}
    }
}

my $text1 = join '', qw(
QN FS LK CM LT HC SM MC VK
IH HA XR QM BQ IE QN AK RD
PS TU CB NX MC IF NX MC IT
YF SD EF IF QN LQ FL YD SB
QN AK EU MC TI IE QN MS IQ
KA PF IL BM WD DF RE IV KA
MC IT QN FX MB FT FT DX AK
HC SM YF WE BA AB QE IV OI
XT IT FM AQ AK QN MX ZU DS
OI XI QN FY RX NV OR RB RA
MC MB NX XM AE OW FT LR NC
IQ QN FM ML SN AH QN QL TW
FL ST LT PI QI QN DS VK AR
FS AQ TI DF SM AK FO XM VA
RZ FT SN GS UD FM SA WA LN
MF IT QN FG LN BQ QE AR VA
DT FT QA AB FY IT MX DK FM
DF QN FX NO XC TF SM FK OY
CM QM BA LH
);

statistics($text1, 2, 4);

my $text2 = join '', qw(
TH ET IM EH AS CO ME HE WH
OK NO WS SH OU LD TH IN KI
MU ST GO MY HE AD MY HE AR
TA RE DE AD TH OS EA WF UL
TH IN GS HE RA LD TH EM OR
NI NG OI LP RI CE SD OW NI
HE AR TH EY PL AN AN EW IN
CO ME TA XD AL LA SC OW BO
YS AR EN OT IN TH ES UP ER
BO WL TH AT SW HY IQ UI TI
HE LP MY SE LF IV AN IS HF
OR TH EN EX TM ON TH SO RY
EA RS AS KB RO TH ER WH IT
ET OT RA CE ME IN CA SE YO
UW AN TM EU RG EN TL YI AM
NE AR TH EF AM OU SC IT YO
FR AN TO LA AT AR ES ID EN
CE TH EY HA VE NA ME DN AV
EH SH AL OM
);


statistics($text2, 2, 4);


my $text3 = join '', qw (
T IVD ZCRTIC FQNIQ TU TF
Q XAVFCZ FEQXC PCQUCZ WK
Q FUVBC FNRRTXTCIUAK WTY
D TUP MCFECXU UV UPC BVANHC
VR UPC FEQXC UPC FUVBC
XVIUQTIF FUVICF NENQAAK
VI UPC UVE UV UQGC Q FQNIQ
WQUP TU IF QAFV ICXCFFQMK
UPQU UPC FUVBC TF EMVECMAK
PCQUCZ QIZ UPQU KVN PQBC
UPC RQXTATUK VR UPMVDTIY
DQUCM VI UPC FUVICF
);

statistics($text3, 1, 0);

