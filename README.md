# koha-plugin-item-stats
Add a link to items to calculate yearly circulation stats

# Item Stats

This plugin adds a link on the item record within the “Date last borrowed” column that will contain yearly stats and local usage stat (if desired) for that particular item. 


Install Plugin
# Configure the Plugin

There are two fields to configure for this plugin, what month in the year to start the statistics (1-12)

An option to include local usage statistics.

# Getting the Stats

From the item holding page, a "Stats!" link will be present within the "Date Last Borrowed Column". Clicking the "Stats!" link will bring a modal popup which will provide the statistics for that item for the time period indicated in the configuration.  If the option to include Local Use stats was set up in the configuration, those stats will be included on a separate line. 
