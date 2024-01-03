package Koha::Plugin::Com::ByWaterSolutions::ItemStats::Controller;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(encode_json);
use Encode qw(encode_utf8);

use CGI;
use Try::Tiny;

use Koha::DateUtils qw( output_pref dt_from_string );

=head1 Koha::Plugin::Com::ByWaterSolutions::ItemStats::Controller
A class for fetching yearly item stats

=head2 Class methods

=head3 get

Controller function that handles getting yearly stats for an item

=cut

sub get {
    my $c = shift->openapi->valid_input or return;

    my $itemnumber = $c->param('item_id');

    my $item_stats = Koha::Plugin::Com::ByWaterSolutions::ItemStats->new();
    my $localuse = $item_stats->retrieve_data('localuse');
    my $types = $localuse ? q{"issue","renew","localuse"} : q{"issue","renew"};
    my $year_start = sprintf('%02s',$item_stats->retrieve_data('year_start')) // '01';
    my $today = output_pref({ str=> dt_from_string, dateformat=>"sql",dateonly=>1 });
    my $cur_month = substr($today,4,2);
    my $cur_year = substr($today,0,4);
    $cur_year++ if( $cur_month > $year_start );

    my $end_of_year = $cur_year . '-' . $year_start . '-01';

    my $dbh = C4::Context->dbh;
    
    return try {

        my $query = q{
            SELECT IF( MONTH(datetime) < ?, YEAR(datetime), YEAR(datetime)+1 ) AS fiscal_year, type, COUNT(*) AS total
            FROM statistics
            WHERE
                itemnumber = ?
                AND DATE(datetime) > DATE_SUB( ?, INTERVAL 2 YEAR)
        };
        $query .= " AND type IN ($types) ";
        $query .= " GROUP BY fiscal_year,type";
        my $sth = $dbh->prepare($query);
        $sth->execute( $year_start, $itemnumber, $end_of_year );
        my $results = $sth->fetchall_arrayref({});
        return $c->render(
            status => 200,
            openapi => $results
       );
        
    }
    catch {
        $c->unhandled_exception($_);
    };
}


1;
