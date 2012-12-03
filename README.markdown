FEATURES:
validations avec arguments
colonnes calculees
conf des associations / foreign_keys
enum values editing
disable completement des tables
improve search (regexp, fulltext ?)
in-place editing sur les belongs_to / custom columns
mass editing / editing ; nullifier des champs
support pour l'édition des associations has many
audit with papertrail
help popin pour la keyboard navigation
i18n
support pour les images
optim de la clause select sql (jarter les text / binaries non selectionnes par les settings)
sortable table for dashboard
more ajax (destroy) / pjax

TODOS:
attr_accessible avec role pour proteger plan sur account
account deprovision ; pour le moment ca supprime la row, on la garde ? que fait-on des collaborators associés ? des données stockées dans redis ?
unset le focus eventuel d'un element de la popin quand on la ferme, sinon le "press s" ne fonctionne plus

BUGS:
column_settings modal sur une has_many/things
une colonne nommé "increment" fait peter le create/update (lors du dirty tracking la methode built in rails increment est incorrectement appelee)
serialized columns containing smth else than a basic type
subnav flickers on a page slightly too long for the screen
on peut pas mettre un espace comme thousand delimiter (or j'aurais bien voulu pouvoir le faire sur une colonne zipcode)

https://adminium.herokuapp.com/resources/accounts?asearch=inactives&order=%22accounts%22.id+desc&search=k.hankinson%40btinternet.com => quand on essaie de virer la search, ça vire la asearch a la place

potential optimisation : https://github.com/bgipsy/column_queries
pour les dangerousattributes, ils sont readonly
