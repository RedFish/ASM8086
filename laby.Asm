		assume cs:code, ds:code, ss:code
		
		code    segment
		
		org     100h
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Zone de déclaration de macro ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClearScreen macro
		push es
		;efface l'écran
		mov ax,0a000h
		mov es,ax
		xor di,di
		mov ax,0h		;couleur
		mov cx,64000	;320x200
		rep stosb
		pop es
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fin de zone de déclaration de macro ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


start:
		;gestion du mode video
		; lit le mode video courant
		mov ah,0fh
		int 10h
		mov mode,al
		
		mov ax,13h
		int 10h
		
;##########################################################################
;######################## Début de la page du menu ########################
;##########################################################################
debut:
		;on affiche l'image de fond du message
		mov dx,offset image_menu
		call fond
		
		;initialisation de l'état de la souris
		mov ax,0
		int 33h
		;bx contient le nombre de bouton de la souris
		
		;forme du curseur
		mov  ax,9h
		mov  bx,8h
		mov  cx,8h
		lea  dx,curseur
		int  33h
		
		;affichage du curseur
		mov ax,1
		int 33h
		
		;definition borne abscisse
		mov ax,7h
		mov cx,0h
		mov dx,270h
		int 33h
		
		;definition borne ordonne
		mov ax,8h
		mov cx,0h
		mov dx,0C0h
		int 33h
		
		;on attribut les couleurs en fonction des positions du curseur.
default_menu:
		mov menu_modif,0
		mov color_m1,0eh
		mov color_m2,0eh
		mov color_m3,0eh
		jmp print_menu
current_menu_1:
		cmp bx,1h
		je jeu
		
		cmp menu_modif,1
		je menu_deja
		mov menu_modif,1
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m1,05h
		mov color_m2,0eh
		mov color_m3,0eh
		jmp print_menu
current_menu_2:
		cmp bx,1h
		je instructions
		
		cmp menu_modif,2
		je menu_deja
		mov menu_modif,2
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m1,0eh
		mov color_m2,05h
		mov color_m3,0eh
		jmp print_menu
current_menu_3:
		cmp bx,1h
		je fin
		
		cmp menu_modif,3
		je menu_deja
		mov menu_modif,3
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m1,0eh
		mov color_m2,0eh
		mov color_m3,05h
		jmp print_menu
		
		
print_menu:
		mov bl,color_m1		;couleur
		lea bp,menu1		;adresse du message
		mov cx,L_menu1		;longueur chaine
		mov dh,0bh			;no ligne
		mov dl,12h			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		mov bl,color_m2		;couleur
		lea bp,menu2		;adresse du message
		mov cx,L_menu2		;longueur chaine
		mov dh,0dh			;no ligne
		mov dl,0eh			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		mov bl,color_m3		;couleur
		lea bp,menu3		;adresse du message
		mov cx,L_menu3		;longueur chaine
		mov dh,0fh			;no ligne
		mov dl,11h			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		jmp aquisition
		
menu_deja:
		;affichage du curseur
		mov ax,1
		int 33h
		
		
aquisition:
		
		;aquisition état et position du curseur
		mov ax,3h
		int 33h
		;bx:état du bouton - cx:position horizontale - dx:position verticale
		
		;on effectue un suite de test pour voir dans quelles zones se trouve le curseur.
		cmp dx,54h
		jl default_menu
		
		cmp cx,0118h
		jl m2
		cmp cx,178h
		jg m2
		cmp dx,64h
		jl current_menu_1
		
m2:		
		cmp cx,0dah
		jl m3
		cmp cx,1a8h
		jg m3
		cmp dx,66h
		jl m3
		cmp dx,74h
		jl current_menu_2
		
m3:		
		cmp cx,104h
		jl default_menu
		cmp cx,188h
		jg default_menu
		cmp dx,76h
		jl default_menu
		cmp dx,84h
		jl current_menu_3
		jmp default_menu
		
;##########################################################################
;######################### Fin de la page du menu #########################
;##########################################################################



;##########################################################################
;############################## Début du jeu ##############################
;##########################################################################
jeu:
		;on initialise le compteur à "00" (en hexa)
		mov compteur_d,30h
		mov compteur_u,30h
		
		;on initialise le score à "99" (en hexa)
		mov score_compteur_d,30h
		mov score_compteur_u,30h
		
		;on initialise le numéro du premier niveau
		mov niveau,1
		
		;on efface le curseur
		mov ax,2h
		int 33h
debut_jeu:
		;on récupere l'offset de la matrice à afficher
		mov ax,niveau
		call select_niveau
		
		;on efface l'écran
		ClearScreen
		
		;on affiche le niveau
		call affichage_labyrinthe
		
		;on affiche le numéro du niveau
		call aff_no_niveau
		
		;affiche le score
		call aff_score
		
		;on initialise la position courante avec la position du personnage
		mov cx,pos_x
		mov dx,pos_y
		
		;on initialise la variable cle (0:pas de cle,1:cle)
		mov cle,0
		;on initialise la variable épée (0:pas d'épée,1:épée)
		mov epee,0
		
		jmp clavier
;si le mouvement sort du cadre on annule le mouvement, si le personne va vers un mur on annule le mouvement
droite:
		cmp cx,12fh
		jg clavier
		call efface
		lea bx,matrice_homme_droite
		add cx,8h
		call couleur_px
		
		cmp al,15h
		je mouvement_d_vers_mur
		cmp al,37h
		je mouvement_vers_cle
		cmp al,0f8h
		je mouvement_d_vers_porte
		cmp al,0f6h
		je mouvement_vers_epee
		cmp al,29h
		je mouvement_vers_monstre
		jmp afficher_personnage
		
		
mouvement_d_vers_mur:
		sub cx,8h
		jmp afficher_personnage
mouvement_d_vers_porte:
		cmp cle,1
		je niveau_suivant
		sub cx,8h
		jmp afficher_personnage
		
gauche:	
		cmp cx,0h
		jng clavier
		call efface
		lea bx,matrice_homme_gauche
		sub cx,8h
		call couleur_px
		
		cmp al,15h
		je mouvement_g_vers_mur
		cmp al,37h
		je mouvement_vers_cle
		cmp al,0f8h
		je mouvement_g_vers_porte
		cmp al,0f6h
		je mouvement_vers_epee
		cmp al,29h
		je mouvement_vers_monstre
		jmp afficher_personnage
		
mouvement_g_vers_mur:
		add cx,8h
		jmp afficher_personnage
mouvement_g_vers_porte:
		cmp cle,1
		je niveau_suivant
		add cx,8h
		jmp afficher_personnage
		
haut:	
		cmp dx,0h
		jng clavier
		call efface
		lea bx,matrice_homme_dos
		sub dx,8h
		call couleur_px
		
		cmp al,15h
		je mouvement_h_vers_mur
		cmp al,37h
		je mouvement_vers_cle
		cmp al,0f8h
		je mouvement_h_vers_porte
		cmp al,0f6h
		je mouvement_vers_epee
		cmp al,29h
		je mouvement_vers_monstre
		jmp afficher_personnage
		
mouvement_h_vers_mur:
		add dx,8h
		jmp afficher_personnage
mouvement_h_vers_porte:
		cmp cle,1
		je niveau_suivant
		add dx,8h
		jmp afficher_personnage
		
bas:	
		cmp dx,0b3h
		jg clavier
		call efface
		lea bx,matrice_homme_face
		add dx,8h
		call couleur_px
		
		cmp al,15h
		je mouvement_b_vers_mur
		cmp al,37h
		je mouvement_vers_cle
		cmp al,0f8h
		je mouvement_b_vers_porte
		cmp al,0f6h
		je mouvement_vers_epee
		cmp al,29h
		je mouvement_vers_monstre
		jmp afficher_personnage
		
mouvement_b_vers_mur:
		sub dx,8h
		jmp afficher_personnage
mouvement_b_vers_porte:
		cmp cle,1
		je niveau_suivant
		sub dx,8h
		jmp afficher_personnage
		
		
		
		;action commune au 4 mouvements
mouvement_vers_cle:
		call aff_cle
		mov cle,1
		jmp afficher_personnage
mouvement_vers_epee:
		call aff_epee
		mov epee,1
		jmp afficher_personnage
mouvement_vers_monstre:
		cmp epee,1
		jne game_over
		call aff_inc_score
		jmp afficher_personnage
		
		
		;affichage du personnage
afficher_personnage:	
		call aff_img
clavier:	
		;on récupere le caractère - sa valeur en hexa dans al
		mov ah,8
		int 21h
		
		;saut en fonction de la touche saisie.
controle:
		;détection du mouvement
		;;;;;;;;;;;;;;;;;;;;;;;;;;
		;controle avec les lettres
		;;;;;;;;;;;;;;;;;;;;;;;;;;
		cmp al,64h
		je droite
		cmp al,71h
		je gauche
		cmp al,7Ah
		je haut
		cmp al,73h
		je bas
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;si 'esc' on revient au menu principale.
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		cmp al,1bh
		je debut
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;commande de triche: 'n' puis 'entrer'
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		cmp al,6eh
		jne clavier
		int 21h
		cmp al,20h
		je niveau_suivant
		;En cas de touche non défini on retourne a la saisie clavier.
		jmp clavier
		
niveau_suivant:
		inc niveau
		cmp niveau,10
		jle debut_jeu
		

;##########################################################################
;############################### Fin du jeu ###############################
;##########################################################################



;##########################################################################
;###################### Début de la page de victoire ######################
;##########################################################################
		;on charge l'image de victoire
		lea dx,image_victoire
		call fond
		
		;on affiche le curseur
		mov ax,1h
		int 33h
		
		;on attribut les couleurs en fonction des positions du curseur.
jeu_default_menu:
		mov menu_modif,0
		mov color_m5,0eh
		mov color_m4,0eh
		jmp jeu_print_menu
jeu_current_menu_5:
		cmp bx,1h
		je debut
		
		cmp menu_modif,5
		je jeu_menu_deja
		mov menu_modif,5
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m5,05h
		mov color_m4,0eh
		jmp jeu_print_menu
jeu_current_menu_4:
		cmp bx,1h
		je jeu
		
		cmp menu_modif,4
		je jeu_menu_deja
		mov menu_modif,4
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m5,0eh
		mov color_m4,05h
		jmp jeu_print_menu
		
		
jeu_print_menu:
		mov bl,color_m5		;couleur
		lea bp,menu5		;adresse du message
		mov cx,L_menu5		;longueur chaine
		mov dh,13h			;no ligne
		mov dl,0ch			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		mov bl,color_m4		;couleur
		lea bp,menu4		;adresse du message
		mov cx,L_menu4		;longueur chaine
		mov dh,013h			;no ligne
		mov dl,17h			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		jmp jeu_aquisition
		
jeu_menu_deja:
		;affichage du curseur
		mov ax,1
		int 33h
		
		
jeu_aquisition:
		
		;aquisition état et position du curseur
		mov ax,3h
		int 33h
		;bx:état du bouton - cx:position horizontale - dx:position verticale
		
		;on effectue un suite de test pour voir dans quelles zones se trouve le curseur.
		cmp dx,93h
		jl jeu_default_menu
		cmp dx,0a3h
		jg jeu_default_menu
		
		cmp cx,0b0h
		jl jeu_default_menu
		cmp cx,110h
		jle jeu_current_menu_5
		
		cmp cx,164h
		jl jeu_default_menu
		cmp cx,1e8h
		jle jeu_current_menu_4
		jmp jeu_default_menu
		
;##########################################################################
;####################### Fin de la page de victoire #######################
;##########################################################################



;##########################################################################
;##################### Début de la page de 'Game Over' ####################
;##########################################################################

game_over:
		;on charge l'image de fin de jeu
		lea dx,image_game_over
		call fond
		
		;on affiche le curseur
		mov ax,1h
		int 33h
		
		;on attribut les couleurs en fonction des positions du curseur.
over_default_menu:
		mov menu_modif,0
		mov color_m5,0eh
		mov color_m4,0eh
		jmp over_print_menu
over_current_menu_5:
		cmp bx,1h
		je debut
		
		cmp menu_modif,5
		je over_menu_deja
		mov menu_modif,5
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m5,05h
		mov color_m4,0eh
		jmp over_print_menu
over_current_menu_4:
		cmp bx,1h
		je over_clear_curseur
		
		cmp menu_modif,4
		je over_menu_deja
		mov menu_modif,4
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m5,0eh
		mov color_m4,05h
		jmp over_print_menu
		
		
over_print_menu:
		mov bl,color_m5		;couleur
		lea bp,menu5		;adresse du message
		mov cx,L_menu5		;longueur chaine
		mov dh,13h			;no ligne
		mov dl,0ch			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		mov bl,color_m4		;couleur
		lea bp,menu4		;adresse du message
		mov cx,L_menu4		;longueur chaine
		mov dh,013h			;no ligne
		mov dl,17h			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		jmp over_aquisition
		
over_menu_deja:
		;affichage du curseur
		mov ax,1
		int 33h
		
		
over_aquisition:

		;aquisition état et position du curseur
		mov ax,3h
		int 33h
		;bx:état du bouton - cx:position horizontale - dx:position verticale
		
		;on effectue un suite de test pour voir dans quelles zones se trouve le curseur.
		cmp dx,93h
		jl over_default_menu
		cmp dx,0a3h
		jg over_default_menu
		
		cmp cx,0b0h
		jl over_default_menu
		cmp cx,110h
		jle over_current_menu_5
		
		cmp cx,164h
		jl over_default_menu
		cmp cx,1e8h
		jle over_current_menu_4
		jmp over_default_menu
		
over_clear_curseur:
		;on efface le curseur
		mov ax,2h
		int 33h
		
		;on décremente le conteur des niveaux
		cmp compteur_u,30h
		jne sub_unit
		mov compteur_u,39h
		cmp compteur_d,30h
		jne add_dix
		mov compteur_d,39h
		jmp debut_jeu
		
sub_unit:
		sub compteur_u,1
		jmp debut_jeu
sub_dix:
		sub compteur_d,1
		
		jmp debut_jeu
		
;##########################################################################
;####################### Fin de la page de 'Game Over' ####################
;##########################################################################



;##########################################################################
;###################### Début de la page instruction ######################
;##########################################################################
instructions:
		;on efface le curseur
		mov ax,2h
		int 33h
		
		lea dx,image_instructions
		call fond
		
		;on affiche le curseur
		mov ax,1h
		int 33h
		
		;on attribut les couleurs en fonction des positions du curseur.
inst_default_menu:
		mov menu_modif,0
		mov color_m1,0eh
		mov color_m6,0eh
		jmp inst_print_menu
inst_current_menu_1:
		cmp bx,1h
		je jeu
		
		cmp menu_modif,1
		je inst_menu_deja
		mov menu_modif,1
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m1,05h
		mov color_m6,0eh
		jmp inst_print_menu
inst_current_menu_6:
		cmp bx,1h
		je debut
		
		cmp menu_modif,6
		je inst_menu_deja
		mov menu_modif,6
		;efface le curseur
		mov ax,2
		int 33h
		
		mov color_m1,0eh
		mov color_m6,05h
		
		
inst_print_menu:
		mov bl,color_m1		;couleur
		lea bp,menu1		;adresse du message
		mov cx,L_menu1		;longueur chaine
		mov dh,15h			;no ligne
		mov dl,0ch			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		mov bl,color_m6		;couleur
		lea bp,menu6		;adresse du message
		mov cx,L_menu6		;longueur chaine
		mov dh,015h			;no ligne
		mov dl,17h			;no colonne
		mov ax,1300h		;fonction ecrire chaine
		int 10h	
		
		jmp inst_aquisition
		
inst_menu_deja:
		;affichage du curseur
		mov ax,1
		int 33h
		
		
inst_aquisition:
		;aquisition état et position du curseur
		mov ax,3h
		int 33h
		;bx:état du bouton - cx:position horizontale - dx:position verticale
		
		;on effectue un suite de test pour voir dans quelles zones se trouve le curseur.
		cmp dx,0a3h
		jl inst_default_menu
		cmp dx,0b3h
		jg inst_default_menu
		
		cmp cx,0b8h
		jl inst_default_menu
		cmp cx,118h
		jle inst_current_menu_1
		
		cmp cx,164h
		jl inst_default_menu
		cmp cx,1dch
		jle inst_current_menu_6
		jmp inst_default_menu
		
;##########################################################################
;####################### Fin de la page instruction #######################
;##########################################################################



;##########################################################################
;######################### Début de la page de fin ########################
;##########################################################################
fin:
		;effacement du curseur
		mov ax,2h
		int 33h
		
		lea dx,image_fin
		call fond
		
		;temporisation
		mov cx,038h
tempo:
		push cx
		mov cx,0FFFFh
tempo1:
		push cx
		mov ax,8600h
		mov cx,0
		mov dx,0FFFFh
		int 15h
		pop cx
		loop tempo1
		pop cx
		loop tempo
		
		
		;restaure l'ancien mode video
		mov ah,0
		mov al,mode
		int 10h
		
		mov ah,4ch
		int 21h
		
;##########################################################################
;########################## Fin de la page de fin #########################
;##########################################################################


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Zone de déclaration des procedures ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;procedure qui affiche l'image de fond (paramètre: offset de l'image dans dx)
fond	proc
		mov ah,3dh		; ouvre le fichier
		mov al,00h
		int 21h
		mov handle,ax
		
		mov ah,3fh		; lit entete + palette
		mov dx,offset entete
		mov cx,1078
		mov bx,handle
		int 21h
		
		mov bx,54		; changement de palette
		mov dx,03c8h
		mov al,00h
		out dx,al
		mov dx,03c9h
palet:
		mov al,entete[bx+2]
		sar al,1
		sar al,1
		out dx,al
		mov al,entete[bx+1]
		sar al,1
		sar al,1
		out dx,al
		mov al,entete[bx]
		sar al,1
		sar al,1
		out dx,al
		add bx,4
		cmp bx,1078
		jne palet
		
		mov cx,320		; preparation a la lecture
		mov dx,64000
		mov bx,handle
		mov ax,0a000h
		mov ds,ax
lectu:
		mov ah,3fh		; lecture de l'image
		int 21h
		or dx,dx
		jz suite
		sub dx,320
		jmp lectu
		
suite:
		mov ax,cs		; retablit DS
		mov ds,ax
		
		mov ah,3eh		; ferme le fichier
		mov bx,handle
		int 21h
		
		mov bx,0		; sauvegarde des zones animees
		mov di,0
		mov ax,0a000h
		mov cx,cs
sauve:
		mov ds,ax
		mov dl,[di+320*60]
		mov ds,cx
		mov sauveg[di],dl
		inc di
		cmp di,320*44
		jne sauve
		
		ret
fond	endp

;---------------------------------
;-- Début des procedures du jeu --
;---------------------------------

;procedure qui renvoie l'offset du niveau a afficher en fonction de la valeur de ax
select_niveau proc near
		cmp ax,1
		je niveau_1
		cmp ax,2
		je niveau_2
		cmp ax,3
		je niveau_3
		cmp ax,4
		je niveau_4
		cmp ax,5
		je niveau_5
		cmp ax,6
		je niveau_6
		cmp ax,7
		je niveau_7
		cmp ax,8
		je niveau_8
		cmp ax,9
		je niveau_9
		cmp ax,10
		je niveau_10
		
niveau_1:
		lea bx,L1
		ret
niveau_2:
		lea bx,L2
		ret
niveau_3:
		lea bx,L3
		ret
niveau_4:
		lea bx,L4
		ret
niveau_5:
		lea bx,L5
		ret
niveau_6:
		lea bx,L6
		ret
niveau_7:
		lea bx,L7
		ret
niveau_8:
		lea bx,L8
		ret
niveau_9:
		lea bx,L9
		ret
niveau_10:
		lea bx,L10
		ret
select_niveau endp

;procedure qui affiche le labyrinthe (parametre: offset du labyrinthe dans bx & retourne pos_x,pos_y)
affichage_labyrinthe proc near
		
		;on definie la limite de la matrice (40*24-1)
		mov limit,bx
		add limit,959d
		
		;initialisation des points dans le coin h/g
		mov cx,-1	;ligne
		mov dx,-2	;colonne
		
		jmp prem_aff
aff_laby:
		;on ajoute 8 (taille d'un motif)
		add cx,8
		cmp cx,13fh
		jl inc_bx
		mov cx,-1
		add dx,8
inc_bx:
		;on incrémente l'offset de un pour lire la valeur suivante
		inc bx
prem_aff:
		push bx
		push dx
		;on récupere l'offset de la valeur a lire dans la matrice
		mov dx,[bx]
		
		
		;on test pour voir de quoi il s'agit et on saute a la récupération de l'offset
		cmp dl,0h
		je test_aff_laby_fin
		cmp dl,1h
		je motif_mur
		cmp dl,2h
		je motif_porte
		cmp dl,3h
		je motif_cle
		cmp dl,4h
		je motif_homme_face
		cmp dl,5h
		je motif_homme_dos
		cmp dl,6h
		je motif_homme_gauche
		cmp dl,7h
		je motif_homme_droite
		cmp dl,8h
		je motif_princesse
		cmp dl,9h
		je motif_prison
		cmp dl,0ah
		je motif_epee
		cmp dl,0bh
		je motif_monstre
		
		;on récupere l'offset du motif à afficher
motif_mur:
		lea bx,matrice_mur
		jmp affiche_motif
motif_porte:
		lea bx,matrice_porte
		jmp affiche_motif
motif_cle:
		lea bx,matrice_cle
		jmp affiche_motif
motif_homme_face:
		lea bx,matrice_homme_face
		jmp affiche_motif
motif_homme_dos:
		lea bx,matrice_homme_dos
		jmp affiche_motif
motif_homme_gauche:
		lea bx,matrice_homme_gauche
		jmp affiche_motif
motif_homme_droite:
		lea bx,matrice_homme_droite
		jmp affiche_motif
motif_princesse:
		lea bx,matrice_princesse
		jmp affiche_motif
motif_prison:
		lea bx,matrice_prison
		jmp affiche_motif
motif_epee:
		lea bx,matrice_epee
		jmp affiche_motif
motif_monstre:
		lea bx,matrice_monstre
		jmp affiche_motif
		
affiche_motif:
		;si 3<dl<8 alors il s'agit du personneage donc on récupere la position
		cmp dl,4h
		jl affiche_motif2
		cmp dl,7h
		jg affiche_motif2
		pop dx
		mov pos_x,cx
		mov	pos_y,dx
		jmp affiche_motif3
affiche_motif2:
		pop dx
affiche_motif3:
		;on affiche le motif
		call aff_img
		jmp test_aff_laby_fin2
		
		;on test si l'on a pas atteint la limite de fin de la matice du labyrinthe
test_aff_laby_fin:
		pop dx
test_aff_laby_fin2:
		pop bx
		cmp bx,limit
		jne aff_laby
		
		ret
affichage_labyrinthe endp

;procedure qui affiche un motif (paramètre: offset du motif dans bx)
aff_img proc near
		push cx
		push dx
		
		inc cx
		inc dx 
		
		;on definie la limite des abscisses de la matrice du motif selon la position
		mov limit_ligne_img,cx
		add limit_ligne_img,8
		
		;on definie la limite de la matrice du motif selon la position
		mov limit_img,bx
		add limit_img,63d	;8*8-1
		
		jmp prem_aff_pt
aff_point_start:
		inc cx
		cmp cx,limit_ligne_img
		jl inc_bx_pt
		sub cx,8h
		inc dx
inc_bx_pt:
		inc bx
prem_aff_pt:
		push dx
		mov dx,[bx]
		
		;on test pour voir de quoi il s'agit
		cmp dl,0h
		je noir
		cmp dl,1h
		je gris_mur
		cmp dl,2h
		je gris_porte
		cmp dl,3h
		je jaune
		cmp dl,4h
		je rouge_brique
		cmp dl,5h
		je brun
		cmp dl,6h
		je rose_peau
		cmp dl,7h
		je bleu
		cmp dl,8h
		je rouge
		cmp dl,9h
		je rose_princesse
		cmp dl,0ah
		je blanc
		cmp dl,0bh
		je vert
		
		;on attibut la couleur de la pallette à la matrice
noir:
		mov al,0h
		jmp aff_point
gris_mur:
		mov al,0f7h
		jmp aff_point
gris_porte:
		mov al,0f8h
		jmp aff_point
jaune:
		mov al,37h
		jmp aff_point
rouge_brique:
		mov al,15h
		jmp aff_point
brun:
		mov al,16h
		jmp aff_point
rose_peau:
		mov al,0a7h
		jmp aff_point
bleu:
		mov al,0fch
		jmp aff_point
rouge:
		mov al,0f9h
		jmp aff_point
rose_princesse:
		mov al,87h
		jmp aff_point
blanc:
		mov al,0f6h
		jmp aff_point
vert:	mov al,29h
		jmp aff_point
		
		;on affiche le point avec la bonne couleur definie plus haut
aff_point:
		pop dx
		
		;fonction écrire pixel
		mov ah,0Ch
		int 10h
		jmp test_aff_motif_fin2
		
		;on test si l'on a pas atteint la limite de fin de la matice du motif
test_aff_motif_fin:
		pop dx
test_aff_motif_fin2:
		cmp bx,limit_img
		jne aff_point_start
		
		pop dx
		pop cx
		
		ret
aff_img endp

;procedure qui affiche le numéro du niveau (il s'incrémente automatiquement à chaque appel
aff_no_niveau proc near
		
		cmp compteur_u,39h
		jne add_unit
		mov compteur_u,30h
		cmp compteur_d,39h
		jne add_dix
		mov compteur_d,30h
		jmp affichage_no
		
add_unit:
		add compteur_u,1
		jmp affichage_no
add_dix:
		add compteur_d,1
		
affichage_no:
		; ecrire une chaine de caractère
		mov ax,1300h
		mov bx,7h				;couleur
		mov dh,18h				;no ligne
		mov dl,0h				;no colonne
		mov cx,L_message_niveau	;longueur chaine
		lea bp,message_niveau	;adresse du message
		int 10h	
		
		; affichage du compteur
		;dizaine
		mov ax,1300h			
		mov bl,7h				;couleur
		mov dh,18h				;no ligne
		mov dl,07h				;no colonne
		mov cx,1				;longueur chaine
		lea bp,compteur_d		;adresse du message
		int 10h	
		;unité
		mov ax,1300h			
		mov bl,7h				;couleur
		mov dh,18h				;no ligne
		mov dl,08h				;no colonne
		mov cx,1				;longueur chaine
		lea bp,compteur_u		;adresse du message
		int 10h	
		
		ret
aff_no_niveau endp

;procedure qui affiche le score (il s'incrémente automatiquement à chaque appel)
aff_inc_score proc near
		push cx
		push dx
		push bx
		
		cmp score_compteur_u,39h
		jne score_add_unit
		mov score_compteur_u,30h
		cmp score_compteur_d,39h
		jne score_add_dix
		mov score_compteur_d,30h
		jmp score_affichage_no
		
score_add_unit:
		add score_compteur_u,1
		jmp score_affichage_no
score_add_dix:
		add score_compteur_d,1
		
score_affichage_no:
		; ecrire une chaine de caractère
		mov ax,1300h
		mov bx,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,1eh					;no colonne
		mov cx,L_message_score		;longueur chaine
		lea bp,message_score		;adresse du message
		int 10h	
		
		; affichage du compteur
		;dizaine
		mov ax,1300h			
		mov bl,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,24h					;no colonne
		mov cx,1					;longueur chaine
		lea bp,score_compteur_d		;adresse du message
		int 10h	
		;unité
		mov ax,1300h			
		mov bl,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,25h					;no colonne
		mov cx,1					;longueur chaine
		lea bp,score_compteur_u		;adresse du message
		int 10h	
		;multiplie par 10
		mov ax,1300h			
		mov bl,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,26h					;no colonne
		mov cx,1					;longueur chaine
		lea bp,score_compteur_0		;adresse du message
		int 10h	
		
		pop bx
		pop dx
		pop cx
		ret
aff_inc_score endp

;affiche simplement le score
aff_score proc near
		push cx
		push dx
		push bx
		
		
		; ecrire une chaine de caractère
		mov ax,1300h
		mov bx,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,1eh					;no colonne
		mov cx,L_message_score		;longueur chaine
		lea bp,message_score		;adresse du message
		int 10h	
		
		; affichage du compteur
		;dizaine
		mov ax,1300h			
		mov bl,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,24h					;no colonne
		mov cx,1					;longueur chaine
		lea bp,score_compteur_d		;adresse du message
		int 10h	
		;unité
		mov ax,1300h			
		mov bl,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,25h					;no colonne
		mov cx,1					;longueur chaine
		lea bp,score_compteur_u		;adresse du message
		int 10h	
		;multiplie par 10
		mov ax,1300h			
		mov bl,7h					;couleur
		mov dh,18h					;no ligne
		mov dl,26h					;no colonne
		mov cx,1					;longueur chaine
		lea bp,score_compteur_0		;adresse du message
		int 10h	
		
		pop bx
		pop dx
		pop cx
		ret
aff_score endp

;procedure qui efface un carré de 8px*8px
efface proc near
		push cx
		push dx
		
		;taille du carré
		mov lxx,cx
		mov lyy,dx
		add lxx,8h
		add lyy,8h
		
		;etat de s'il est déja rentré dans la bouble:0=non 1=oui
		mov etat,0
		
carrex0:
		add cx,1h
		;si c'est la premiere fois qu'on rentre, on ne réinitialise pas yy
		cmp etat,1
		jne carrey0
		sbb dx,8h
carrey0:
		add dx,1h
		
		;on initialise etat a 1 car on est entré dans la boucle
		mov etat,1
		
		;affiche un pixel
		mov ah,0Ch				;fonction écrire pixel
		mov al,0h				;couleur
		int 10h
		
		;tant que l'on a pas parcourut la colonne on continue
		cmp dx,lyy
		jne carrey0
		
		;tant que l'on a pas parcourut la ligne on continue
		cmp cx,lxx
		jne carrex0
		
		;on récupère la position du pixel dans la pile.
		pop dx
		pop cx
		
		ret
efface endp

;porcedure qui renvoie la couleur du pixel(posistion 4,4) du motif a tester (parametre: position dans cx,cx & retourne la couleur en hexa dans al)
couleur_px proc near
		add cx,4h
		add dx,4h
		
		;lecture du pixel - sa couleur sera stocké dans al
		mov ah,0dh
		int 10h
		
		sub cx,4h
		sub dx,4h
		
		ret
couleur_px endp

;procedure qui affiche la cle lorsqu'on la possède.
aff_cle proc near
		push bx
		push cx
		push dx
		mov cx,50h
		mov dx,0bfh
		lea bx,matrice_cle
		call aff_img
		pop dx
		pop cx
		pop bx
		ret
aff_cle endp

;procedure qui affiche la eppe lorsqu'on la possède.
aff_epee proc near
		push bx
		push cx
		push dx
		mov cx,59h
		mov dx,0bfh
		lea bx,matrice_epee
		call aff_img
		pop dx
		pop cx
		pop bx
		ret
aff_epee endp

;--------------------------------
;-- Fin des procedures du jeu ---
;--------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fin de la zone de déclaration des procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Zone de déclaration des variables ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;contient le mode video du systeme avant l'exécution du programme
mode db ?

;;;;;;;;;;;;;;;;;;;
;;variables image;;
;;;;;;;;;;;;;;;;;;;
image_menu db "img_1.bmp",0
image_instructions db "img_2.bmp",0
image_victoire db "img_3.bmp",0
image_game_over db "img_4.bmp",0
image_fin db "img_5.bmp",0
handle dw ?
entete	db 1078 dup(?)
sauveg	db 14080 dup(?)
;;;;;;;;;;;;;;;;;;;

;variable qui est modifiée si on change de menu
menu_modif db ?

;menu 1
color_m1 db ?
menu1 db "Jouer"
L_menu1 equ $-menu1
;menu 2
color_m2 db ?
menu2 db "Instructions"
L_menu2 equ $-menu2
;menu 3
color_m3 db ?
menu3 db "Quitter"
L_menu3 equ $-menu3
;menu 4
color_m4 db ?
menu4 db "Rejouer"
L_menu4 equ $-menu4
;menu 5
color_m5 db ?
menu5 db "Menu"
L_menu5 equ $-menu5
;menu 6
color_m6 db ?
menu6 db "Retour"
L_menu6 equ $-menu6

;masque du curseur
curseur	dw  1111111001111111b	;Background
		dw  1111100110011111b
		dw  1110011111100111b
		dw  1110011111100111b
		dw  1111100110011111b
		dw  1111111001111111b
		dw  1111111001111111b
		dw  1111111001111111b
		dw  1111111001111111b
		dw  1111111001111111b
		dw  1111111001111111b
		dw  1111111001111111b
		dw  1111111000000111b
		dw  1111111000001111b
		dw  1111111000011111b
		dw  1111111000000111b
		
		dw  0000000110000000b	;start curseur
		dw  0000011001100000b
		dw  0001100000011000b
		dw  0001100000011000b
		dw  0000011001100000b
		dw  0000000110000000b
		dw  0000000110000000b
		dw  0000000110000000b
		dw  0000000110000000b
		dw  0000000110000000b
		dw  0000000110000000b
		dw  0000000110000000b
		dw  0000000111111000b
		dw  0000000111110000b
		dw  0000000111100000b
		dw  0000000111111000b

;--------------------------------------------------------------------------
;------------- Début des déclarations de variable du jeu ------------------
;--------------------------------------------------------------------------

;contient l'offset limite de la matrice du labyrinthe
limit dw ?

;contient le niveau courant
niveau dw ?

;message pour laffichage du numéro du niveau
message_niveau db "Niveau"
L_message_niveau equ $-message_niveau

;message pour laffichage du numéro du niveau
message_score db "score:"
L_message_score equ $-message_score

;contient le numéro du niveau
compteur_u db ?
compteur_d db ?

;contient le score
score_compteur_u db ?
score_compteur_d db ?
score_compteur_0 db 30h

;contient la positon du personnage après l'affichage du niveau
pos_x dw ?
pos_y dw ?

;variable pour la procedure aff_img
limit_img dw ?
limit_ligne_img dw ?

;variable pour la procedure 
xx dw ?
yy dw ?
lxx dw ?
lyy dw ?
etat dw ?

;variable de la cle (0:non,1:oui)
cle db ?

;variable de l'épée (0:non,1:oui)
epee db ?

;déclaration des matrices des motifs
matrice_mur db 1,1,1,1,1,1,1,1
			db 1,4,4,4,1,4,4,4
			db 1,1,1,1,1,1,1,1
			db 4,4,1,4,4,4,1,4
			db 4,4,1,4,4,4,1,4
			db 1,1,1,1,1,1,1,1
			db 1,4,4,4,1,4,4,4
			db 1,4,4,4,1,4,4,4

matrice_porte	db 0,0,0,2,5,0,0,0
				db 0,2,5,2,5,2,5,0
				db 0,2,5,2,5,2,5,0
				db 5,2,5,2,5,2,5,2
				db 5,2,5,2,5,2,3,2
				db 5,2,5,2,5,2,5,2
				db 5,2,5,2,5,2,5,2
				db 5,2,5,2,5,2,5,2

matrice_cle	db 8 dup(0)
			db 0,0,0,0,0,0,3,0
			db 0,0,0,0,0,3,0,3
			db 3,3,3,3,3,0,0,3
			db 3,3,0,0,0,3,0,3
			db 0,0,0,0,0,0,3,0
			db 8 dup(0)
			db 8 dup(0)

matrice_homme_face 	db 0,0,0,6,6,0,0,0
					db 0,0,6,6,6,6,0,0
					db 0,0,0,6,6,0,0,0
					db 0,7,7,7,7,7,7,0
					db 0,6,7,7,7,7,6,0
					db 0,6,8,8,8,8,6,0
					db 0,0,8,0,0,8,0,0
					db 0,6,6,0,0,6,6,0

matrice_homme_dos 	db 0,0,0,5,5,0,0,0
					db 0,0,6,5,5,6,0,0
					db 0,0,0,6,6,0,0,0
					db 0,7,7,7,7,7,7,0
					db 0,6,7,7,7,7,6,0
					db 0,6,8,8,8,8,6,0
					db 0,0,8,0,0,8,0,0
					db 0,6,6,0,0,6,6,0

matrice_homme_gauche	db 0,0,0,6,5,0,0,0
						db 0,0,6,6,5,0,0,0
						db 0,0,0,6,6,0,0,0
						db 0,0,7,7,7,0,0,0
						db 0,0,7,6,7,0,0,0
						db 0,0,8,6,8,0,0,0
						db 0,0,0,0,8,0,0,0
						db 0,0,0,6,6,0,0,0

matrice_homme_droite	db 0,0,0,5,6,0,0,0
						db 0,0,0,5,6,6,0,0
						db 0,0,0,6,6,0,0,0
						db 0,0,0,7,7,7,0,0
						db 0,0,0,7,6,7,0,0
						db 0,0,0,8,6,8,0,0
						db 0,0,0,8,0,0,0,0
						db 0,0,0,6,6,0,0,0

matrice_princesse	db 0,0,0,3,3,0,0,0
					db 0,0,0,6,6,0,0,0
					db 0,0,0,6,6,0,0,0
					db 0,0,0,9,9,0,0,0
					db 0,0,6,9,9,6,0,0
					db 0,9,6,9,9,6,9,0
					db 9,9,9,9,9,9,9,9
					db 0,0,6,0,0,6,0,0

matrice_prison	db 0,2,0,2,0,2,0,2
				db 0,2,0,2,0,2,0,2
				db 2,2,2,2,2,2,2,2
				db 0,2,0,2,0,2,0,2
				db 0,2,0,2,0,2,0,2
				db 2,2,2,2,2,2,2,2
				db 0,2,0,2,0,2,0,2
				db 0,2,0,2,0,2,0,2

matrice_epee	db 0,0,0,0,0,0,0,0
				db 0,1,1,0,0,0,0,0
				db 0,1,10,1,0,0,0,0
				db 0,0,1,10,1,0,0,0
				db 0,0,0,1,10,1,3,0
				db 0,0,0,0,1,3,0,0
				db 0,0,0,0,3,0,3,0
				db 0,0,0,0,0,0,0,3

matrice_monstre	db 0,0,1,0,0,1,0,0
				db 0,0,0,11,11,0,0,0
				db 0,0,0,11,11,0,0,0
				db 0,11,11,11,11,11,11,0
				db 1,11,0,11,11,0,11,1
				db 2,0,0,11,11,0,0,2
				db 0,0,11,11,11,11,0,0
				db 0,2,2,0,0,2,2,0

;definition des matrice des labyrinthes
L1	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,4,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,1,0,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,8,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,9,9,9,9,9,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,0,0,0,3,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

L2	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,4,1,0,0,3,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,1,0,1,11,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,10,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

L3	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,7,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,3,1,0,1,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,10,1,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,0,1,1,1,0,1,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,0,1,1,1,0,1,0,1,1,1,11,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	
L4	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,3,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,0,1,1,1,11,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,10,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,1,1,1,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,6,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,0,1,0,0,0,0,0,11,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	
L5	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,10,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,1,1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1,0,1,1,1,11,1,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,0,1,1,1,0,1,0,1,1,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,3,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,1,7,0,0,0,0,11,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

L6	db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	db 1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1
	db 1,11,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,1,0,1
	db 1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,1,0,0,1
	db 1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,1
	db 1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,1
	db 1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,0,1
	db 1,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,1
	db 1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,1
	db 7,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1
	db 1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1,0,1
	db 1,0,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,0,0,0,1
	db 1,0,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,0,1,0,1,1
	db 1,0,0,0,0,0,1,0,0,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,1
	db 1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1
	db 1,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,1
	db 1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1
	db 1,0,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,0,1,0,1
	db 1,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,10,1,0,0,0,1,0,0,0,1,0,1,0,3,1,0,0,0,1
	db 1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	
L7	db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	db 2,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
	db 1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1
	db 1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,1,10,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1
	db 1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1
	db 1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1
	db 1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,1
	db 1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,11,1,1,0,1
	db 1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1
	db 1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,0,1
	db 1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,1,0,0,0,0,0,0,1
	db 1,0,1,1,1,11,1,1,1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,1
	db 1,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,1
	db 1,1,1,0,1,0,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1,0,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,0,1
	db 1,0,0,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,1
	db 1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,1
	db 1,0,1,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,1,0,1,3,0,1
	db 1,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,11,0,0,1
	db 1,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

L8	db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	db 1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1
	db 1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,1
	db 1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,11,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,1
	db 1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,1,3,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,0,1,0,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1
	db 1,0,0,0,0,10,1,0,1,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,0,1,0,1,1,1,1,0,1,1,1,0,1,1,1,1,1,11,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1
	db 1,0,0,0,0,0,0,0,1,0,11,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,1
	db 1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1
	db 1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,1
	db 1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1
	db 1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,1,0,1,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,0,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1,11,1,1,1,1,1,1,1
	db 1,0,0,0,0,0,0,0,1,0,1,0,1,0,1,1,1,0,1,1,1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1
	db 1,0,1,1,1,1,1,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1
	db 1,0,0,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1
	db 1,1,1,0,1,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,11,0,1,0,0,0,1,0,1,0,1,0,0,1
	db 1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,1
	db 1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,1
	db 1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,1
	db 7,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,2
	db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

L9	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,3,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
	db 0,0,0,0,1,0,0,0,11,0,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,0,11,0,0,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,1,0,1,0,1,11,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,11,1,0,1,0,1,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,11,0,0,0,11,0,0,0,1,1,1,1,1,11,1,1,1,1,1,0,0,0,11,0,0,0,11,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,1,1,1,1,1,0,1,11,1,1,1,1,0,0,0,1,1,1,1,11,1,0,1,11,1,11,1,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,0,0,0,6,1,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,11,10,0,0,0,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,1,1,1,1,1,11,1,11,1,1,1,1,0,0,0,1,1,1,1,11,1,0,1,11,1,11,1,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,0,0,11,0,0,0,11,0,1,1,1,1,1,11,1,1,1,1,1,0,0,0,11,0,0,0,11,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,11,1,0,1,0,1,0,1,0,0,0,0,0
	db 0,0,0,0,1,0,11,0,0,0,11,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,0,11,0,0,0,1,0,0,0,0,0
	db 0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,3,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

L10	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,1,0,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,8,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,9,9,9,9,9,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,7,0,0,0,3,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;--------------------------------------------------------------------------
;-------------- Fin des déclarations de variable du jeu -------------------
;--------------------------------------------------------------------------


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Fin de zone de déclaration des variables ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		code    ends
		
end start











