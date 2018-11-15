+++++ +++++          # bunku cislo 0 inicializovat na 10 #
[                    # pouzit cyklus pro inicializaci nasledujicich tri bunek na hodnoty 130/100/50 #
 > +++++ +++++ +++   # pricist 13 k bunce cislo1 #
 > +++++ +++++       # pricist 10 k bunce cislo2 #
 > +++++             # pricist 5 k bunce cislo3 #
 <<< -               # vratit se a dekrementovat hodnotu bunky cislo0#
]
>                    # prejdeme na bunku s hodnotou 130 #
----------.          tisk znaku "x"
>++++++++.           tisk znaku "l"
+++.                 tisk znaku "o"
--------.            tisk znaku "g"
++.                  tisk znaku "i"
+++++.               tisk znaku "n"
>--.                 #tisk znaku "0" #
+.                   #tisk znaku "1" #

#
Tento kod lze tak, jak jej vidite tj. vcetne komentaru odsmimulovat 
pomoci debuggeru na adrese http://www.fit.vutbr.cz/~vasicek/inp18/
#



+++++ +++++          # bunku cislo 0 inicializovat na 10 #
[                    # pouzit cyklus pro inicializaci nasledujicich tri bunek na hodnoty 130/100/50 #
 > +++++ +++++ +++   # pricist 13 k bunce cislo1 #
 > +++++ +++++       # pricist 10 k bunce cislo2 #
 > +++++             # pricist 5 k bunce cislo3 #
 <<< -               # vratit se a dekrementovat hodnotu bunky cislo0#
]
>                    # prejdeme na bunku s hodnotou 130 #
----------.          znak "x"
>+++.                znak "g"
<------.             znak "r"
>--.		     znak "e"
++.		     znak "g"
<+++.		     znak "u"
>>--.		     #znak "0" #
++.		     #znak "2" #

Real output:
++++++++++[>+++++++++++++>++++++++++>+++++<<<-]>----------.>+++.<------.>--.++.<+++.>>--.++.
