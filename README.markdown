## Sequel Migration TODOS / FIXMES :

  - composite primary keys for import, bulk edit
  - empty string => nil in forms ?
  - Account#db_url_validation ; still effective ? cleanup missing
  - in place edit not honoring permissions
  - support for views

## FEATURES:

freaking TIMEZONES !!
gerer les serialized lors de l'edit/update
utiliser rack-timeout
validations avec arguments
colonnes calculees
conf des associations / foreign_keys
disable completement des tables
improve search (regexp, fulltext ?)
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
in-place edit improvements :
	- country, time_zone
	- belongs_to
	- custom columns in index
gestion de tables sans PK : pour le moment on peut creer, on pourrait supprimer (delete from table where <tous les attr> limit 1)
fail on forms ameliorables (highlight des champs en erreur)

## TODOS:

attr_accessible avec role pour proteger plan sur account
données stockées dans redis pour les comptes deprovisionnés ?
unset le focus eventuel d'un element de la popin quand on la ferme, sinon le "press s" ne fonctionne plus

## BUGS:

lors d'un export ; rajout d'un has_many/count column puis export => colonne vide, nouvel export => colonne remplie
serialized columns containing smth else than a basic type
subnav flickers on a page slightly too long for the screen
on peut pas mettre un espace comme thousand delimiter (or j'aurais bien voulu pouvoir le faire sur une colonne zipcode)
pas de completion des tables sur la page d'edition de compte
