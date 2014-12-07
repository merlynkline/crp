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

    return if $latitude < -90 || $latitude > 90 || $longitude <= -180 || $longitude >= 180;
    my $latitude_offset = $distance / KM_PER_DEGREE_LATITUDE;
    my $longitude_offset = $distance / (cos($latitude * PI / 180) * KM_PER_DEGREE_LATITUDE);
    my $location_condition = [
        -and => [
            latitude => {'>', $latitude - $latitude_offset},
            latitude => {'<', $latitude + $latitude_offset}
        ]
    ];
    my $nearby_resultset = $self->search($location_condition);
    $location_condition = [
        -and => [
            longitude => {'>', $longitude - $longitude_offset},
            longitude => {'<', $longitude + $longitude_offset}
        ]
    ];
    $nearby_resultset = $nearby_resultset->search($location_condition);
    return $nearby_resultset->search($condition);
}

1;

