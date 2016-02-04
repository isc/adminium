### Sequel Migration TODOS / FIXMES :
  - composite primary keys for import, bulk edit
  - bug time chart day of week ; 2 sundays

### FEATURES:
- nullifier une date depuis l'edit plus facilement
- pour remplir une date null dans l'edit il faut selectionner une heure sinon ca reste null
- nullifier autre chose que des string dans le cadre d'un bulk edit
- types exotiques : inet, uuid, hstore
- gerer les serialized lors de l'edit/update (pas evident ; unsafe, piste RubyParser pour mitigate cf dbinsights, reste qu'un time inspected ne se parse pas naturellement en retour)
- validations avec arguments
- colonnes calculees
- conf des associations / foreign_keys
- disable completement des tables
- faire du dependent destroy sur les associations
- improve search (regexp, fulltext (http://tech.pro/tutorial/1142/building-faceted-search-with-postgresql))
- support pour l'édition des associations has many
- audit with papertrail
- i18n
- support pour les images
- optim de la clause select sql (jarter les text / binaries non selectionnes par les settings)
- supprimer plusieurs pages de records en une action
- more ajax (destroy) / pjax
- for pg 9.2 users ; https://github.com/will/datascope
- advanced search definition improvements :
  - select input for column with enum values defined
- gerer les colonnes binary (file field for upload ?)
- in-place edit improvements :
	- country, time_zone
	- belongs_to
	- custom columns in index
- gestion de tables sans PK : pour le moment on peut creer, on pourrait supprimer (delete from table where <tous les attr> limit 1)
- fail on forms ameliorables (highlight des champs en erreur)

### TODOS:
- attr_accessible avec role pour proteger plan sur account
- données stockées dans redis pour les comptes deprovisionnés ?

### BUGS:
- cas de l'install / switch sur une app heroku ou ca fail sur la db url
- column settings sur une colonne d'une table associée ; quand on change la visibilité ca s'applique sur le listing de la table associee, pas la table de depart.
- searchable columns only integer, rechercher une string ne veut rien dire mais ramene tous les results
- ugly show avec une text column bien remplie (https://www.adminium.io/resources/stories/15 sur enigmatic-beach-4845)
- serialized columns containing smth else than a basic type
- on peut pas mettre un espace comme thousand delimiter (or j'aurais bien voulu pouvoir le faire sur une colonne zipcode)

### Refacto
- remplir une date / un timestamp ne fonctionne pas sur firefox
- clickable area des accordéons de settings popins
- color polyfill for safari
