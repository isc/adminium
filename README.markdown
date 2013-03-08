FEATURES:

pouvoir plus facilement ajouter un nouveau record a une association
tweaker le page title
utiliser rack-timeout
validations avec arguments
colonnes calculees
conf des associations / foreign_keys
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

more ajax (destroy) / pjax
for pg 9.2 users ; https://github.com/will/datascope
advanced search definition improvements :
  - select input for column with enum values defined

404 moche quand on tape un faux nom de table en haut
gerer joliment les 404 sur le show d'une table existante d'un user (genre "There is no user with id 3442")

gerer les colonnes binary (file field for upload ?)

TODOS:
attr_accessible avec role pour proteger plan sur account
account deprovision ; pour le moment ca supprime la row, on la garde ? que fait-on des collaborators associés ? des données stockées dans redis ?
unset le focus eventuel d'un element de la popin quand on la ferme, sinon le "press s" ne fonctionne plus

BUGS:
label column fonctionne pas juste apres configuration (jamais ?) sur metrics-recorder
une colonne nommé "increment" fait peter le create/update (lors du dirty tracking la methode built in rails increment est incorrectement appelee)
serialized columns containing smth else than a basic type
subnav flickers on a page slightly too long for the screen
on peut pas mettre un espace comme thousand delimiter (or j'aurais bien voulu pouvoir le faire sur une colonne zipcode)

pas de completion des tables sur la page d'edition de compte

potential optimisation : https://github.com/bgipsy/column_queries
pour les dangerousattributes, ils sont readonly
