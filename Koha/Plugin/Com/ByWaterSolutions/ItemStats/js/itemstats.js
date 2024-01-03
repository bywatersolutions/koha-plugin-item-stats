$(document).ready(function(){
if( $("#catalog_detail").length > 0 ){

    function add_itemstats_data(itemnumber,stats){
        let result = '<tr class="stats_row" id="item_stats_'+itemnumber+'"><td class="stat"><fieldset>';
        result +=    '<legend>Item statistics: </legend>';
        result +=    '<ul>'
        if( stats.length > 0 ){
            $.each(stats,function(index,year){
                let type_desc = "";
                if( year.type == 'issue' ){
                    type_desc = ' Checkouts: ';
                } else if ( year.type == 'renew' ){
                   type_desc = ' Renewals: ';
                } else if ( year.type == 'localuse' ){
                   type_desc = ' Localuse: ';
                }
                result +=      '<li>';
                result +=      year.fiscal_year + type_desc;
                result +=      '' + year.total + '';
                result +=      '</li>';
            });
        } else {
            result += "<li>No circulations in past 2 years</li>";
        }
        result +=    '</ul>';
        result +=    '</fieldset></td></tr>';
        $("#itemstats_modal_results").append(result);
    }

    function get_itemstats_data(itemnumber){

        $(".stats_row").hide();

        let item_stats = $("#item_stats_"+itemnumber);
        if( item_stats.length > 0 ){
             $(item_stats).show();
             return;
        }

		let options = {
			url: '/api/v1/contrib/itemstats/itemstats/'+itemnumber,
			method: "GET",
			contentType: "application/json",
			data: ''
		};
		$.ajax(options)
			.then(function(result) {
					add_itemstats_data( itemnumber, result );
			})
			.fail(function(err){
				 console.log( _("There was an error fetching the resources") + err.responseText );
			});
    }

    $("#holdings_table tr").each(function(){
        let itemnumber = $(this).data('itemnumber');
        stats_button = '</br><a  class="stats_button" data-itemnumber='+itemnumber+'>Stats!</a>';
        $(this).children('td.datelastborrowed').append(stats_button);
    });
    $("body").on('click','.stats_button',function(){
        get_itemstats_data( $(this).data('itemnumber') );
        $("#itemstats_modal").modal().show();
    });

}
});
