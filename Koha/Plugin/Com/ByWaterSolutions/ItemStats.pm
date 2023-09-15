package Koha::Plugin::Com::ByWaterSolutions::ItemStats;

use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);


use JSON qw(decode_json);

## We will also need to include any Koha libraries we want to access
use C4::Context;

## Here we set our plugin version
our $VERSION = "{VERSION}";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name          => 'Pay Via Govolution',
    author        => 'Nick Clemens',
    description   => 'This plugin enables online OPAC fee payments via Govolution',
    date_authored => '2023-05-30',
    date_updated  => '1900-01-01',
    minimum_version => '22.05.00.000',
    maximum_version => undef,
    version         => $VERSION,
};


sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            application_id => $self->retrieve_data('application_id'),
            enable_opac_payments => $self->retrieve_data('enable_opac_payments'),
            url => $self->retrieve_data('url'),
            debug => $self->retrieve_data('debug'),
        );

        print $cgi->header();
        print $template->output();
    }
    else {
        $self->store_data(
            {
                application_id       => $cgi->param('application_id'),
                enable_opac_payments => $cgi->param('enable_opac_payments'),
                url                  => $cgi->param('url'),
                debug                => $cgi->param('debug'),
            }
        );
        $self->go_home();
    }
}

sub intranet_head {
    my ( $self ) =@_;

    return q|
        <style>
            #itemstats_modal_results {
                display: flex;
                flex-direction: column;
            }
            #itemstats_results {
                font-weight: 700;
                padding-left: 1em;
            }
            .itemstats_result_bottom {
                border-bottom: 1px solid #000;
            }
            .itemstats_result_bottom td {
                padding-bottom: 10px;
            }
        </style>
        <div id="itemstats_modal" class="modal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="closebtn" data-dismiss="modal" aria-label="Close">x</button>
                        <h3 class="modal-title">Item stats!</h3>
                    </div>
                    <div class="modal-body">
                        <table id="itemstats_modal_results" class="table">
                        </table>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    |;
}

sub intranet_js {
    my ( $self ) = @_;

    return q|
    <script src="/api/v1/contrib/itemstats/static/js/itemstats.js"></script>
    |;
}

sub install() {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh();

    my $table = $self->get_qualified_table_name('tokens');
    my $query = "
		CREATE TABLE IF NOT EXISTS $table
		  (
			 token          VARCHAR(128),
			 created_on     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			 borrowernumber INT(11) NOT NULL,
             accountline_ids VARCHAR(255) NOT NULL,
             amount         DECIMAL(28,6),
             parcel         TEXT,
             application_id VARCHAR(255),
             security_id    VARCHAR(255) NULL DEFAULT NULL,
			 PRIMARY KEY (token),
			 CONSTRAINT token_bn FOREIGN KEY (borrowernumber) REFERENCES borrowers (
			 borrowernumber ) ON DELETE CASCADE ON UPDATE CASCADE
		  )
		ENGINE=innodb
		DEFAULT charset=utf8mb4
		COLLATE=utf8mb4_unicode_ci;
    ";

    return $dbh->do( $query );

}

sub uninstall() {
    return 1;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('staticapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'itemstats';
}

1;
