#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;
use Data::Dumper;

my $login = "XXXXXX";
my $password = "XXXXXXXX";

my $url = "https://info.santaenergy.com/";

my $date = `date`;
chomp($date);
print $date . ",";

# login
my $mech = WWW::Mechanize->new();
$mech->cookie_jar(HTTP::Cookies->new);
$mech->get($url);
$mech->set_visible( $login, $password );
$mech->click('cmdLogin');
die unless ($mech->success);
my $output = $mech->content;
my @lines = split('\n',$output);

my $near=0;
foreach my $line (@lines) {
    if ($near) {
       print "Daily price -> " .  &format($line);
       $near=0;
    }
    if ($line =~ /Santa Daily Price/) {
          $near++;
    };
}; # end each line

$mech->get("https://info.santaenergy.com/priceprotection");
my $priceprotections = $mech->content;
@lines = split('\n',$priceprotections);

$near=0;
foreach my $line (@lines) {
    if ($near==1) {
       $near++;
       next;
    }
    if ($near==2) {
       print "pre-buy price -> " .  &format($line);
       $near=0;
    }
    if ($line =~ /Pre-buy Price/) {
          $near=1;
    };
}; # end each line


# ------------ subs ----------
sub format {
 my $input = shift;
 $input =~ s/<td.*">//g;
 $input =~ s/<\/td>.*//g;
 $input =~ s/<td.*">//g;
 $input =~ s/<\/td>.*//g;
 return $input;
}

print "\n";

