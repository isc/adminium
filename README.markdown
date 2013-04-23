Sequel Migration TODOS / FIXMES :
- migration des données Redis
  - "account:17:settings:PhoneNumber" => "account:17:settings:phone_numbers"
  - listing columns ; user.pseudo => users.pseudo
- composite primary keys
- validations
- reset_adminium_demo_settings
- statistics

FEATURES:
freaking TIMEZONES !!
gerer les serialized lors de l'edit/update
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
i18n
support pour les images
optim de la clause select sql (jarter les text / binaries non selectionnes par les settings)
supprimer plusieurs pages de records en une action

more ajax (destroy) / pjax
for pg 9.2 users ; https://github.com/will/datascope
advanced search definition improvements :
  - select input for column with enum values defined

gerer les colonnes binary (file field for upload ?)

TODOS:
attr_accessible avec role pour proteger plan sur account
données stockées dans redis pour les comptes deprovisionnés ?
unset le focus eventuel d'un element de la popin quand on la ferme, sinon le "press s" ne fonctionne plus

BUGS:
label column fonctionne pas juste apres configuration (jamais ?) sur metrics-recorder
une colonne nommé "increment" fait peter le create/update (lors du dirty tracking la methode built in rails increment est incorrectement appelee)
serialized columns containing smth else than a basic type
subnav flickers on a page slightly too long for the screen
on peut pas mettre un espace comme thousand delimiter (or j'aurais bien voulu pouvoir le faire sur une colonne zipcode)

pas de completion des tables sur la page d'edition de compte

pour les dangerousattributes, ils sont readonly
