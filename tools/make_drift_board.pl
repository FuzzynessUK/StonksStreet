#!/usr/bin/perl
# Builds boards/drifting_isles.json: Drifting Isles, a main board with four
# islands floating loose round it.
#
# A ring in the middle (the Bank, lots, the Star, the Moon, an Arcade) and an
# island off each side, each a loop of eight spaces holding one suit, its own
# lots and a yellow switch. The islands start docked against the ring, joined
# to the ring space beside each. Landing on a switch sends its island out to
# sea, cut off, with anyone on it; they go round the island until somebody
# calls it back. Pressing it again (from the ring or from the island itself)
# sails it back in to dock. Every island's
# switch is on the far side of the ring from it, and one on the island lets
# anyone stranded there call it home.
#
# Map coordinates (x right, y down) are also the board's own: a flat board.
# An island's spaces are placed where it docks; adrift it is shifted $DRIFT out. The layout leaves room for 4;
# everything is moved in afterwards so the map starts at 0, 0.
#
#   perl tools/make_drift_board.pl
use strict;
use warnings;
use FindBin;

my $DRIFT = 2;  # how far an island drifts out from the ring
my (@spaces, %at, %price);
my %first = (A => 100, B => 140, C => 180, D => 220, E => 160, F => 240, G => 260, H => 280, I => 300);
my %suit = (Spade => '#4a78ff', Heart => '#ff3b4a', Diamond => '#ffcc1f', Club => '#22d65a');
my @names = ("Driftwood Diner", "Coral Cafe", "Shell Shop", "Tide Teas", "Kelp Kitchen", "Anchor Arcade",
	"Buoy Books", "Gull Grill", "Reef Records", "Sandbar Sweets", "Lagoon Lamps", "Pearl Pies",
	"Harbour Hats", "Mangrove Market", "Barnacle Bakery", "Seaweed Spa", "Lighthouse Lounge", "Rope Rugs",
	"Cove Comics", "Starfish Shoes", "Pebble Post", "Clam Cakes", "Wave Works", "Crab Cinema",
	"Dune Dairy", "Oyster Optics", "Palm Pizza", "Squid Sundaes", "Jetty Jams", "Marina Mugs",
	"Tidepool Toys", "Coconut Cones", "Surf Sandals", "Breeze Bikes", "Lagoon Laundry", "Otter Outfits");

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
sub switch { return ("switch", platform => $_[0]); }

# The ring, clockwise from its top-left corner (7,7) to (15,13). The middle of
# each side is where that side's island docks; each island's switch is on the
# opposite side.
my @ring_cells = (
	[7, 7, "depot"], [8, 7, lot("A")], [9, 7, lot("A")], [10, 7, switch("south")], [11, 7, "wildcard"],
	[12, 7, lot("B")], [13, 7, lot("B")], [14, 7, "dice"], [15, 7, lot("B")],
	[15, 8, lot("C")], [15, 9, switch("west")], [15, 10, "arcade"], [15, 11, lot("C")], [15, 12, lot("C")],
	[15, 13, "interest"], [14, 13, lot("D")], [13, 13, lot("D")], [12, 13, switch("north")], [11, 13, "wildcard"],
	[10, 13, "plot"], [9, 13, lot("D")], [8, 13, lot("E")], [7, 13, "break"],
	[7, 12, lot("E")], [7, 11, switch("east")], [7, 10, "dice"], [7, 9, "plot"], [7, 8, "plot"],
);
my @ring = map { put(@$_) } @ring_cells;
both($ring[$_], $ring[($_ + 1) % @ring]) for 0 .. $#ring;

# An island: eight spaces round a 3 x 3 loop centred on (cx, cy), docked
# against the ring on side (dx, dy). Its cells go round from the one facing
# the ring, which joins the ring space next to it while docked.
my @round = ([0, -1], [1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1]);
my %platforms;
sub island {
	my ($name, $cx, $cy, $dx, $dy, $block, $mark) = @_;
	my ($start) = grep { $round[$_][0] == $dx && $round[$_][1] == $dy } 0 .. 7;
	my @cells = ([lot($block)], [lot($block)], [switch($name)], [lot($block)], [relay($mark)],
		[lot($block)], ["wildcard"], [lot($block)]);
	my @ids;
	for my $k (0 .. 7) {
		my $r = $round[($start + $k) % 8];
		push @ids, put($cx + $r->[0], $cy + $r->[1], @{ $cells[$k] });
	}
	both($ids[$_], $ids[($_ + 1) % 8]) for 0 .. 7;
	$platforms{$name} = {
		look => "island",
		spaces => \@ids,
		start => 1,  # docked
		states => [
			{ shift => [-$dx * $DRIFT, -$dy * $DRIFT], links => [] },  # adrift, out at sea
			{ shift => [0, 0], links => [[id_at($cx + 2 * $dx, $cy + 2 * $dy), $ids[0]]] },  # docked
		],
	};
}
island("north", 11, 5, 0, 1, "F", "Spade");
island("east", 17, 10, -1, 0, "G", "Heart");
island("south", 11, 15, 0, -1, "H", "Diamond");
island("west", 5, 10, 1, 0, "I", "Club");

# Move it all in by the room the islands do not use.
for (@spaces) { $_->{x} -= 4 - $DRIFT; $_->{y} -= 4 - $DRIFT; }

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
my @out = ("{", "  \"name\": \"Drifting Isles\",", "  \"theme\": \"lagoon\",", "  \"goal\": 10000,",
	"  \"start_cash\": 1500,", "  \"base_salary\": 200,", "  \"relay_bonus\": 120,",
	"  \"blocks\": " . j(\%blocks) . ",", "  \"platforms\": " . j(\%platforms) . ",", "  \"spaces\": [");
for my $i (0 .. $#spaces) {
	my %sp = %{ $spaces[$i] };
	$sp{id} = $i;
	push @out, "    " . j(\%sp) . ($i < $#spaces ? "," : "");
}
push @out, "  ]", "}";
open my $f, '>', "$FindBin::Bin/../boards/drifting_isles.json" or die;
print $f join("\n", @out), "\n";
close $f;
my %types;
$types{$_->{type}}++ for @spaces;
printf "Drifting Isles: %d spaces (%s) -> boards/drifting_isles.json\n", scalar @spaces,
	join(", ", map { "$types{$_} $_" } sort keys %types);
