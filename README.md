# github-periodic-summary
Get a periodic digest of pull requests a bit different from what github offers.

I haven't figured out yet exactly what I want and the script is pretty hokey. Will update here when it's useful.

## Installation
1. Copy github-summary.cfg.sample to github-summary.cfg
2. If you don't already have an api token, get one from your github profile settings under developer settings. It needs "repo" access.
3. Fill github-summary.cfg.
4. Copy github-summary-lastcursor.cfg to the folder you chose for GITHUB\_SUMMARY\_PATH in github-summary.cfg.
   * This needs to be seeded. TODO. Can do manually by running a query in the explorer (https://developer.github.com/v4/explorer) like this:  
   query {
     repository(owner:"civicrm", name:"civicrm-core") {
       pullRequests(first:1, orderBy:{field:UPDATED_AT, direction:DESC}) {
         edges {
           node {
             number
           }
           cursor
         }
       }
     }
   }
   * The output will contain a value for "cursor" that you can put in the github-summary-lastcursor.cfg as a seed value.
5. Set up a cron script. At the moment it needs to include a cd to the path of the script (TODO: Use $HOME/.github-summary or something as a fixed location for the .cfg file). This example would run every day at 08:00:
   * `0 8 * * * jsmith cd /path/to/folder && /path/to/folder/github-summary.sh`
