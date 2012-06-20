FEATURES:
validations avec arguments
associations has_many dans le listing
colonnes calculees
conf des associations / foreign_keys
enum values editing
disable completement des tables

improve search (regexp, fulltext ?)
in-place editing sur les belongs_to
mass editing / editing ; nullifier des champs
renommage de colonnes
support pour l'édition des associations has many
audit with papertrail
help popin pour la keyboard navigation
i18n
support pour les images
decouverte des associations par foreign keys
optim de la clause select sql (jarter les text / binaries non selectionnes par les settings)
sortable table for dashboard

TODOS:
attr_accessible avec role pour proteger plan sur account
account deprovision ; pour le moment ca supprime la row, on la garde ? que fait-on des collaborators associés ? des données stockées dans redis ?
unset le focus eventuel d'un element de la popin quand on la ferme, sinon le "press s" ne fonctionne plus


BUGS:
on peut pas virer une advanced search appliquée en cliquant sur la croix du label
serialized columns containing smth else than a basic type
subnav flickers on a page slightly too long for the screen

bug sur le param order dans le cadre d'un enchainement de search

potential optimisation : https://github.com/bgipsy/column_queries
pour les dangerousattributes, ils sont readonly
