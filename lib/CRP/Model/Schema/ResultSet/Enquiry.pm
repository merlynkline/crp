package CRP::Model::Schema::ResultSet::Enquiry;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';


use constant KM_PER_DEGREE_LATITUDE => 111.045;
use constant PI => 3.141592654;
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_near_location {
    my $self = shift;
    my($latitude, $longitude, $distance, $condition) = (shift, shift, shift, shift);

    return if $latitude < -90 || $latitude > 90 || $longitude < 0 || $longitude >= 360;
    my $latitude_offset = $distance / KM_PER_DEGREE_LATITUDE;
    my $longitude_offset = cos($latitude * PI / 180) * KM_PER_DEGREE_LATITUDE;
    my $location_condition = [
        -and => [
            -and => [ latitude => {'>', $latitude - $latitude_offset}, {'<', $latitude + $latitude_offset} ],
            -and => [ longitude => {'>', $longitude - $longitude_offset}, {'<', $longitude + $longitude_offset} ],
        ]
    ];
    $condition = $condition ? [ -and => $location_condition, [ $condition ] ] : $location_condition;
    return $self->search($condition, @_);
}

1;

