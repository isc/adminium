FEATURES:
validations avec arguments
associations has_many dans le listing
colonnes calculees
conf des associations / foreign_keys
enum values editing
disable completement des tables
CRUD conf on tables (disable add or delete for instance)
improve search (regexp, fulltext ?)
in-place editing dans le listing (deja les booleens comme typus puis les textes et numbers why not)
mass editing
renommage de colonnes
support pour l'édition des associations has many
audit with papertrail
export csv/xml/json
  -> inclure des champs des modeles lies dans l'export
keyboard navigation (ala commit list sur github)
i18n
support pour les images
mysql compat
decouverte des associations par foreign keys
optim de la clause select sql (jarter les text / binaries non selectionnes par les settings)
sortable table for dashboard

TODOS:
fetching account infos (name, email) is broken
attr_accessible avec role pour proteger plan sur account
account deprovision ; pour le moment ca supprime la row, on la garde ? que fait-on des collaborators associés ? des données stockées dans redis ?


BUGS:
bug dans les params sur un enchainement de plusieurs searches
serialized columns containing smth else than a basic type
subnav flickers on a page slightly too long for the screen 
edit form, pour le compte dbinsights, l'édition d'une query, le select du belongs to account mets nop-prod pour toutes les queries
bug mystique ; de temps en temps je me retrouve avec 0 dans les settings / miscellaneous / per page, alors que j'ai meme pas ouvert le pane mais resultat ca empeche de save settings.

potential optimisation : https://github.com/bgipsy/column_queries
