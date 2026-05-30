#la domanda che mi sono fatto quando ho trovato questo dataset è:
#quali fattori determinano il prezzo dello skipass nei
#comprensori sciistici mondiali? esiste un rapporto
#tra la dimensione o altitudine del comprensorio e il prezzo dello skipass?

#https://www.kaggle.com/datasets/ulrikthygepedersen/ski-resorts
#questo è il dataset

install.packages("rio")
install.packages("dplyr")
install.packages("rcompanion")
install.packages("sjmisc")#ovviamente una tantum

library(rio)
library(dplyr)
library(rcompanion)


setwd("C:/Users/AlessandroMacchi/Downloads/Progetti/R/esercitazione 2")

resorts <- import("resorts.csv", encoding = "Latin-1") # latin 1 per gli accenti sui nomi dei rifugi all'estero

str(resorts)
names(resorts)
nrow(resorts)
ncol(resorts)


head(resorts)
summary(resorts)

# il dataset contiene 499 comprensori sciistici e 25 variabili, il significato delle variabili viene esplicato già 
#dal creatore del dataset stesso

#controllo se ci sono NA espliciti
apply(resorts, 2, function(x) sum(is.na(x))) 
#non si vedono NA, ma potrebbero essere valori = 0

#quindi a questo punto lo faccio con i valori = 0
# apply(resorts, 2, function(x) sum(x == 0, na.rm = TRUE)) non funzionava visto che devo selezionare solo le colonne numeriche
             
colonne_num <- sapply(resorts, is.numeric)
apply(resorts[, colonne_num], 2, function(x) sum(x == 0, na.rm = TRUE))   

#ci sono delle colonne con i valori = 0 
# Price 9 zeri, non è possibile che non costi lo skipass
# Total lifts 1 zero, mi sembra strano che non abbia nessun modo di salire alle piste, lo tratto come NA 
# Beginner/Intermediate/Difficult slopes: possibile, un resort può non avere piste di alcune difficoltà specifiche
# Snow cannons 226 ci può stare, non tutti i rifugi hanno neve artificiali 
# Gondola lifts 175 idem, i rifugi piccoli non hanno cabinovie

#trasformo gli zeri che celano un NA in NA, non ho usato il set_na di proposito, una libreria in meno e mi sembrava più leggibile
resorts$Price <- ifelse(resorts$Price == 0, NA, resorts$Price)
resorts$`Total lifts` <- ifelse(resorts$`Total lifts` == 0, 
                                NA, resorts$`Total lifts`)

# verifico che ora gli NA siano comparsi nel conteggio
apply(resorts, 2, function(x) sum(is.na(x)))

table(resorts$Continent)
table(resorts$Country)
table(resorts$`Snow cannons`)
#qui guardo semplicemente man mano le strutture, mi sembra che siano tutte sensate e senza problem

table(resorts$Season)
length(unique(resorts$Season))
#season è praticamente tutta a caso, sono 31 range diversi molto simili tra di loro e 27 unknown

#faccio 4 macro categorie e metto gli unknown a NA
# inverno: mesi nov-mag, stagione invernale
# estate: mesi estivi
# multi stagione: aperti sia in inverno che in estate
# tutto l'anno: aperti tutto l'anno
# NA: unknown

stagioni_inverno <- c("December - April", "November - April", "December - March",
                      "November - May", "October - May", "December - May",
                      "October - April", "April", "October - June", "September - June",
                      "September - May", "March", "December", "July - April",
                      "November - June", "September - April", "November - March")

stagioni_estate <- c("June - October", "June - September", "July - September",
                     "May - September", "July", "May - October", "May",
                     "July - October")

stagioni_multi <- c("November - May, June - August",
                    "December - April, June - August, October - November",
                    "October - November, December - May, June - October")

#lo faccio con un ifelse annidato
resorts$Season <- ifelse(resorts$Season == "Unknown", NA,
                         ifelse(resorts$Season == "Year-round", "Year_round",
                                ifelse(resorts$Season %in% stagioni_multi, "Multi_Stagione",
                                       ifelse(resorts$Season %in% stagioni_estate, "Solo_Estate",
                                              ifelse(resorts$Season %in% stagioni_inverno, "Solo_Inverno",
                                                     NA)))))


table(resorts$Season)

#creo la variabile per il dislivello per un'analisi più facilitata insieme alla divisione per fascia d'altitudine
resorts <- mutate(resorts,
                  Dislivello = `Highest point` - `Lowest point`)

summary(resorts$Dislivello)

resorts$Fascia_Altitudine <- cut(resorts$`Highest point`,
                                 breaks = c(0, 1500, 2500, 3500, 5000),
                                 labels = c("Bassa", "Media", 
                                            "Alta", "Molto_Alta"))

table(resorts$Fascia_Altitudine)

hist(resorts$Price,
     main = "Distribuzione del prezzo dello skipass",
     xlab = "Prezzo")

Moda <- function(x) {
  freq <- table(x)
  names(freq)[which.max(freq)]
}
Moda(resorts$Price) # moda dei prezzi

round(prop.table(table(resorts$Continent)) * 100, 1) #distribuzione percentuale dei resort nei continenti

resorts %>%
  group_by(Continent) %>%
  summarise(
    N = n(),
    Prezzo_Medio = round(mean(Price, na.rm = TRUE), 2),
    Prezzo_Mediano = median(Price, na.rm = TRUE),
    Prezzo_SD = round(sd(Price, na.rm = TRUE), 2)
  )
#confronto delle medie prezzi tra continenti



#la mia ipotesi è che i comprensori più grandi siano più costosi
#faccio vari test singoli per vedere la correlazione 

# H0: la correlazione tra le due variabili è uguale a 0 (nessuna relazione lineare)
# H1: la correlazione tra le due variabili è diversa da 0 (esiste una relazione lineare)

#prezzo vs altitudine massima
cor.test(resorts$`Highest point`, resorts$Price,
         use = "pairwise.complete.obs")
# r ~ 0.41, p < 0.001 -> correlazione positiva 

#prezzo vs numero totale di piste
cor.test(resorts$`Total slopes`, resorts$Price,
         use = "pairwise.complete.obs")
# r ~ 0.31, p < 0.001 -> correlazione positiva

#prezzo vs numero totale di impianti
cor.test(resorts$`Total lifts`, resorts$Price,
         use = "pairwise.complete.obs")
# r ~ 0.10, p = 0.02 -> correlazione debole ma positiva

#prezzo vs dislivello
cor.test(resorts$Dislivello, resorts$Price,
         use = "pairwise.complete.obs")
# r ~ 0.17, p < 0.001 -> correlazione debole ma postiva di nuovo

#in generale, l'altitudine massima e il numero di pista sono le variabili più correlate all'aumento di prezzo
#numero di impianti e dislivello meno, in generale comunque tutte alzano il prezzo quindi si può dire che 
#comprensiorio più grande porta a prezzi più alti




# qui l'ipotesi è: il prezzo medio differisce tra i continenti
# H0: tutte le medie sono uguali
# H1: almeno una media e' diversa significativamente

ANOVA_continenti <- aov(Price ~ Continent, data = resorts)
summary(ANOVA_continenti)
# F = 116.73, p < 0.001 vuol dire che rifiuto H0.
#esiste una differenza significativa nel prezzo medio tra i continenti.

TukeyHSD(ANOVA_continenti)
#vediamo che nord america e oceania si distaccano dagli altri di più, 
#per esempio tra europa e asia c'è poca differenza

#visualizzo con un boxplot, lo abbiamo fatto in statistica e mi sembrava fosse più appropriato
boxplot(Price ~ Continent, data = resorts,
        main = "Prezzo skipass per continente",
        xlab = "Continente",
        ylab = "Prezzo (EUR)",
        col = "lightblue")



#qui si guarda la differenza di prezzo per fascia d'altitudine
# H0: il prezzo medio è uguale tra tutte le fasce di altitudine
# H1: almeno una fascia di altitudine ha un prezzo medio significativamente diverso
ANOVA_altitudine <- aov(Price ~ Fascia_Altitudine, data = resorts)
summary(ANOVA_altitudine)
# F = 41.21, p < 0.001 vuol dire che rifiuto H0.
#il prezzo varia significativamente in base alla fascia di altitudine.

TukeyHSD(ANOVA_altitudine)
#qui si vede che i resort che si distaccano molto di prezzo son quelli di fascia bassa

boxplot(Price ~ Fascia_Altitudine, data = resorts,
        main = "Prezzo skipass per fascia altitudinale",
        xlab = "Fascia altitudinale",
        ylab = "Prezzo (EUR)",
        col = "red")

#considerazioni finali
# sono stati osservati i motivi per cui i resort salgono o scendono di prezzo
# sulla base delle analisi svolte si può affermare che:
#
# 1) dimensione e prezzo: esiste una correlazione positiva
#    significativa tra prezzo e fattori riguardanit le dimensioni.
#    I comprensori piu' grandi e piu' in quota
#    virano verso l' essere piu' costosi.
#
# 2) il continente e' il fattore con l'effetto
#    piu' marcato sul prezzo. Il Nord America
#    presenta prezzi nettamente superiori (media 77.8 euro contro
#    i 42 euro europei). si possono fare solo ipotesi sul perché di ciò, 
#    possono esserci di mezzo fattori culturali e di mercato in generale 
#
# 3) anche raggruppando l'altitudine in classi
#    i resort di fascia bassa risultano 
#    significativamente piu' economici rispetto a quelli di fascia
#    alta e molto alta, confermando la correlazione precedente ed evidenziando
#    delle "tracce" riguardanti il fatto che il prestigio è dato anche dall'altitudine
#
#qualche limite di questo dataset:
#il dataset contiene 9 prezzi mascherati come 0 (trattati come NA)
#la variabile Season aveva 27 "Unknown" e 31 valori unici testuali
#i continenti Oceania e Sud America sono poco rappresentati
#i prezzi possono dipendere da fattori territoriali non specificati come per esempio
#lo stipendio medio di quel continente
#in generale sono pochi record, ma la presenza di molte colonne riesce a far fare qualche analisi anche più approfondita


#potenziali sviluppi!
# 1) si può costruire un modello di machine learning che predica per esempio il prezzo
# di nuove strutture, però probabilmente servirebbero più record per farlo
#
# 2) non è stato analizzato il discorso riguardante per esempio gli snowpark, quelli possono essere 
#influenti sul prezzo
#
# 3) ho visto che esistono dei dataset sulle precipitazioni nevose in quota, si potrebbe
# cercare di integrare in qualche modo un dataset esterno per fare prediction sul meteo
# e avendo le precipitazioni nevose future si risparmierebbe sulla neve sparata 
#
# 4) fare un focus sulle alpi per evitare il bias dei continenti, fattibile ma sempre il problema dei pochi record
#
# 5) sempre con dati climatici, stimare il rischio che in futuro dei comprensori a bassa quota non abbiano più neve
#o al contrario quelli in alto potrebbero non avere bisogno di sparaneve