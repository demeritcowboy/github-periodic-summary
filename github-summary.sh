#!/bin/sh

# For this to work the cron script has to cd to our folder first.
. ./github-summary.cfg
. $GITHUB_SUMMARY_PATH/github-summary-lastcursor.cfg

# format our query in the weirdo way that the api wants
read -r -d '' query << ENDQUERY
{
  "query": "query { repository(owner:\"$GITHUB_REPO_OWNER\", name:\"$GITHUB_REPO_NAME\") { pullRequests(after:\"$GITHUB_SUMMARY_LASTCURSOR\", first:100, orderBy:{field:UPDATED_AT, direction:ASC}) { edges { node { number title updatedAt state bodyText } cursor } } } }"
}
ENDQUERY

# Run query and store results in a file (the quoting weirdness is weird enough below, so we use a file to at least avoid dealting with single quotes that are in the returned result).
curl -s -H "Authorization: bearer $GITHUB_API_TOKEN" -H "Content-type: application/json" -H "Accept: application/json" -X POST -d "$query" https://api.github.com/graphql > $GITHUB_SUMMARY_PATH/github-summary.tmp

# bash doesn't do json, so we call out to php.
# Was hoping this script was simple enough to do all in bash, but at this point maybe should just do this whole script in php.

read -r -d '' phpparam << ENDPHP
\$js = file_get_contents('$GITHUB_SUMMARY_PATH/github-summary.tmp');
\$results = json_decode(\$js);
\$cursor = NULL;
foreach(\$results->data->repository->pullRequests->edges as \$r) {
  echo "{\$r->node->title}\\n";
  echo "https://github.com/civicrm/civicrm-core/pull/{\$r->node->number}\\n";
  echo "Status: {\$r->node->state}\\n";
  echo "Updated: {\$r->node->updatedAt}\\n";
  echo "{\$r->node->bodyText}\\n\\n========================\\n\\n";
  \$cursor = \$r->cursor;
}
if (\$cursor) {
  file_put_contents('$GITHUB_SUMMARY_PATH/github-summary-lastcursor.cfg', "GITHUB_SUMMARY_LASTCURSOR=\$cursor");
}
ENDPHP

msg=$( php -r "$phpparam" );
mail -s "Github Summary" -S "from=$GITHUB_SUMMARY_EMAIL" $GITHUB_SUMMARY_EMAIL << ENDMSG
$msg
ENDMSG

rm -f $GITHUB_SUMMARY_PATH/github-summary.tmp
