global settings un peu moins global
Gerer les tables sans colonne id
configurer des validations par table/colonne
attr_accessible avec role pour proteger plan sur account
support pour l'édition des associations
liens vers association belongs_to dans le listing
reference data
disable completement des tables
i18n
in-place editing dans le listing (deja les booleens comme typus puis les textes et numbers why not)
further down the road ; mass editing
renommage de colonnes

thread safety pour generic.rb => c'est fait mais il y a pas de cleaning des modeles (un after filter pourrait cleaner, mais ca eliminerait le reuse il faudrait de la time based expiration pour pouvoir avoir les deux, ca se complique, a voir)




Gerer les tables avec une colonne new => j'ai rajouté une colonne new sur une table et j'ai pas de soucis (en ayant enlevé tout traitement spécifique à new)