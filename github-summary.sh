#!/bin/sh

. ./github-summary.cfg
. ./github-summary-lastcursor.cfg

# format our query in the weirdo way that the api wants
read -r -d '' query << ENDQUERY
{
  "query": "query { repository(owner:\"civicrm\", name:\"civicrm-core\") { pullRequests(after:\"$GITHUB_SUMMARY_LASTCURSOR\", first:100, orderBy:{field:UPDATED_AT, direction:ASC}) { edges { node { number title updatedAt closed bodyText } cursor } } } }"
}
ENDQUERY

# Run query and store results in a file (the quoting weirdness is weird enough below, so we use a file to at least avoid dealting with single quotes that are in the returned result).
curl -s -H "Authorization: bearer $GITHUB_API_TOKEN" -H "Content-type: application/json" -H "Accept: application/json" -X POST -d "$query" https://api.github.com/graphql > github-summary.tmp

# bash doesn't do json, so we call out to php
read -r -d '' phpparam << ENDPHP
\$js = file_get_contents('github-summary.tmp');
\$results = json_decode(\$js);
foreach(\$results->data->repository->pullRequests->edges as \$r) {
  echo "{\$r->node->title}\\n";
  echo "https://github.com/civicrm/civicrm-core/pull/{\$r->node->number}\\n";
  echo "Closed: {\$r->node->closed}\\n";
  echo "Updated: {\$r->node->updatedAt}\\n";
  echo "{\$r->node->bodyText}\\n\\n========================\\n\\n";
  \$cursor = \$r->cursor;
}
file_put_contents('github-summary-lastcursor.cfg', "GITHUB_SUMMARY_LASTCURSOR=\$cursor");
ENDPHP

msg=$( php -r "$phpparam" );
mail -s "Github Summary" -S "from=$GITHUB_SUMMARY_EMAIL" $GITHUB_SUMMARY_EMAIL << ENDMSG
$msg
ENDMSG

rm -f github-summary.tmp
