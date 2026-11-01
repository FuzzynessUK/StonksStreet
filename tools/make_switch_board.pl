#!/usr/bin/perl
# Builds boards/switch_yard.json: Switch Yard, a board of yellow switches and
# moving platforms.
#
# A square ring (the Bank, lots, the Star, an Arcade) with four suit pods
# outside it, two above and two below, each a 3 x 3 square of spaces round an
# empty middle. Each pair of pods shares one moving platform: a two-space
# bridge that slides along rails between the ring and one pod or the other.
# Landing on a yellow switch slides its bridge across, opening the way to the
# other pod (and shutting the first). Each bridge has one switch on the ring,
# in the middle of its left or right side, and one in each of its two pods, so
# anyone the bridge leaves behind can call it back.
#
# Map coordinates (x right, y down) are also the board's own: a flat board.
#
#   perl tools/make_switch_board.pl
use strict;
use warnings;
use FindBin;

my (@spaces, %at, %price);
my %first = (A => 100, B => 140, C => 180, D => 220, E => 160, F => 260, G => 300, H => 240, I => 280);
my %suit = (Spade => '#4a78ff', Heart => '#ff3b4a', Diamond => '#ffcc1f', Club => '#22d65a');
my @names = ("Gear Garage", "Bolt Bistro", "Piston Pizza", "Lever Lounge", "Cog Cafe", "Crank Comics",
	"Sprocket Shop", "Rivet Records", "Spring Sweets", "Valve Vinyl", "Chain Cinema", "Pulley Post",
	"Ratchet Rugs", "Hinge Hats", "Axle Antiques", "Wrench Works", "Flywheel Foods", "Gasket Gym",
	"Spanner Spa", "Pulley Pies", "Cam Cakes", "Lathe Lamps", "Bearing Books", "Turbine Teas",
	"Widget World", "Socket Shoes", "Nut Noodles", "Washer Wash", "Dynamo Diner", "Motor Market");

# One space at (x, y): [type, extra fields]. Returns its id.
sub put {
	my ($x, $y, $type, %extra) = @_;
	die "two spaces at $x,$y\n" if exists $at{"$x,$y"};
	if ($type eq "lot") {
		my $b = $extra{block};
		$price{$b} //= $first{$b};
		$extra{price} = $price{$b};
		$price{$b} += 20;
	}
	push @spaces, { type => $type, x => $x, y => $y, next => [], %extra };
	$at{"$x,$y"} = $#spaces;
	return $#spaces;
}
sub id_at { my ($x, $y) = @_; my $id = $at{"$x,$y"}; die "no space at $x,$y\n" unless defined $id; $id }
sub both { my ($a, $b) = @_; push @{ $spaces[$a]{next} }, $b; push @{ $spaces[$b]{next} }, $a; }
sub lot { return ("lot", block => $_[0]); }
sub relay { return ("relay", mark => $_[0], color => $suit{$_[0]}); }

# The ring, clockwise from its top-left corner (4,5) to (10,11). Its two
# switches sit in the middle of its left side (the top bridge) and its right
# side (the bottom bridge).
my @ring_cells = (
	[4, 5, lot("A")], [5, 5, lot("A")], [6, 5, lot("A")], [7, 5, "wildcard"],
	[8, 5, lot("B")], [9, 5, lot("B")], [10, 5, lot("B")],
	[10, 6, "dice"], [10, 7, "arcade"], [10, 8, "switch", platform => "bottom"], [10, 9, lot("C")],
	[10, 10, lot("C")], [10, 11, lot("C")],
	[9, 11, lot("D")], [8, 11, lot("D")], [7, 11, "depot"], [6, 11, lot("D")], [5, 11, lot("E")], [4, 11, lot("E")],
	[4, 10, lot("E")], [4, 9, "interest"], [4, 8, "switch", platform => "top"], [4, 7, lot("E")], [4, 6, lot("E")],
);
my @ring = map { put(@$_) } @ring_cells;
both($ring[$_], $ring[($_ + 1) % @ring]) for 0 .. $#ring;

# A pod: eight spaces round a 3 x 3 square centred on (cx, cy), the middle
# left empty, its entrance in the middle of the side facing the ring (dy: +1
# below the pod, -1 above it). `cells` go round from the entrance. Each pod
# has a switch for its side's bridge, so whoever the bridge leaves behind can
# call it back.
my @round = ([0, -1], [1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1]);
sub pod {
	my ($cx, $cy, $dy, $platform, @cells) = @_;
	my ($start) = grep { $round[$_][0] == 0 && $round[$_][1] == $dy } 0 .. 7;
	my @ids;
	for my $k (0 .. 7) {
		my $r = $round[($start + $k) % 8];
		my @cell = $cells[$k][0] eq "switch" ? ("switch", platform => $platform) : @{ $cells[$k] };
		push @ids, put($cx + $r->[0], $cy + $r->[1], @cell);
	}
	both($ids[$_], $ids[($_ + 1) % 8]) for 0 .. 7;
	return @ids;
}
# Above the ring (entrances face down), below it (entrances face up).
pod(5, 1, 1, "top", [lot("F")], [lot("F")], ["switch"], [lot("F")], [relay("Spade")], ["plot"], [lot("F")], ["wildcard"]);
pod(9, 1, 1, "top", [lot("G")], ["plot"], [lot("G")], [relay("Heart")], [lot("G")], ["switch"], [lot("G")], [lot("G")]);
pod(5, 15, -1, "bottom", [lot("H")], [lot("H")], ["switch"], [lot("H")], [relay("Diamond")], ["dice"], [lot("H")], ["break"]);
pod(9, 15, -1, "bottom", [lot("I")], ["plot"], [lot("I")], [relay("Club")], [lot("I")], ["switch"], [lot("I")], [lot("I")]);

# The platforms: two spaces each, in their first place (state 0) over x = 5,
# sliding 4 to the right (state 1) over x = 9, between the ring and a pod's
# entrance.
my %platforms;
for my $p (["top", 4, 3, 5, 2], ["bottom", 12, 13, 11, 14]) {
	my ($name, $near_y, $far_y, $ring_y, $pod_y) = @$p;
	my $near = put(5, $near_y, "junction");
	my $far = put(5, $far_y, "junction");
	both($near, $far);
	$platforms{$name} = {
		spaces => [$near, $far],
		states => [
			{ shift => [0, 0], links => [[id_at(5, $ring_y), $near], [$far, id_at(5, $pod_y)]] },
			{ shift => [4, 0], links => [[id_at(9, $ring_y), $near], [$far, id_at(9, $pod_y)]] },
		],
	};
}

my $n = 0;
for (@spaces) { $_->{name} = $names[$n++ % @names] if $_->{type} eq "lot"; }

# --- write ----------------------------------------------------------------
sub j {
	my ($v) = @_;
	return "null" unless defined $v;
	return "[" . join(", ", map { j($_) } @$v) . "]" if ref $v eq 'ARRAY';
	return "{ " . join(", ", map { "\"$_\": " . j($v->{$_}) } sort keys %$v) . " }" if ref $v eq 'HASH';
	return $v =~ /^-?\d+(\.\d+)?$/ ? $v : "\"$v\"";
}
my @colours = ('#e0703a', '#e8b33f', '#5fae4f', '#3f9ad0', '#9a6ad0', '#e05a95', '#3fc0b0', '#c87a3a', '#7a9a3a');
my %blocks;
my $c = 0;
$blocks{$_} = { name => $_, color => $colours[$c++] } for sort keys %first;
my @out = ("{", "  \"name\": \"Switch Yard\",", "  \"theme\": \"space\",", "  \"goal\": 10000,",
	"  \"start_cash\": 1500,", "  \"base_salary\": 200,", "  \"relay_bonus\": 120,",
	"  \"blocks\": " . j(\%blocks) . ",", "  \"platforms\": " . j(\%platforms) . ",", "  \"spaces\": [");
for my $i (0 .. $#spaces) {
	my %sp = %{ $spaces[$i] };
	$sp{id} = $i;
	push @out, "    " . j(\%sp) . ($i < $#spaces ? "," : "");
}
push @out, "  ]", "}";
open my $f, '>', "$FindBin::Bin/../boards/switch_yard.json" or die;
print $f join("\n", @out), "\n";
close $f;
my %types;
$types{$_->{type}}++ for @spaces;
printf "Switch Yard: %d spaces (%s) -> boards/switch_yard.json\n", scalar @spaces,
	join(", ", map { "$types{$_} $_" } sort keys %types);
