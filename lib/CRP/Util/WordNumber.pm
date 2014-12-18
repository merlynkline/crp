package CRP::Util::WordNumber;

use strict;
use warnings;

use List::MoreUtils;

my $DIGITS = [
    [qw(her your my his their our)],
    [qw(big small tiny lovely sweet pretty cute tichy dear winsome adorable charming funny large long short mini)],
    [qw(red orange yellow green blue purple pink violet golden silver emerald white lime lemon olive turquoise teal magenta)],
    [qw(baby girls boys kids childs infant tots toddler kiddie newborn)],
    [qw(trousers onesie bib shoes booties hat bonnet ribbon bow leggings jacket slippers socks gloves cap pants scarf)],
];


use constant mask1 => 0x00550055;
use constant d1 => 7;
use constant mask2 => 0x0000cccc;
use constant d2 => 14;

sub encipher {
    my($number) = @_;

    $number += 1337;
    my $t = ($number ^ ($number >> d1)) & mask1;
    my $u = $number ^ $t ^ ($t << d1);
    $t = ($u ^ ($u  >> d2)) & mask2;
    my $y = $u ^ $t ^ ($t << d2);
    return $y;
}

sub decipher {
    my($number) = @_;

    my $t = ($number ^ ($number >> d2)) & mask2;
    my $u = $number ^ $t ^ ($t << d2);
    $t = ($u ^ ($u >> d1)) & mask1;
    my $z = $u ^ $t ^ ($t << d1);
    return $z - 1337;
}

sub encode_number {
    my($number) = @_;

    $number = encipher($number);
    my $string = '';
    my $place = $#$DIGITS;
    do {
        my $digit = $number % @{$DIGITS->[$place]};
        $string = $DIGITS->[$place]->[$digit] . "-$string";
        $number = int $number / @{$DIGITS->[$place]};
        $place--;
    } while($place >= 0 && $number);
    $string = "$number-$string" if $number;
    return substr $string, 0, -1;
}

sub decode_number {
    my($string) = @_;

    return decipher($string) if $string =~ m{^\d+$};
    my @parts = split '-', $string;
    my $multiplier = 1;
    my $place = $#$DIGITS;
    my $number = 0;
    while(@parts && $place >= 0) {
        my $digit = pop @parts;
        $digit = List::MoreUtils::first_index { $_ eq $digit } @{$DIGITS->[$place]};
        $number += $digit * $multiplier;
        $multiplier *= @{$DIGITS->[$place]};
        $place--;
    }
    $number += $multiplier * pop @parts if @parts;
    return decipher($number);
}

