About
=====

Deze repository bevat 2 Perl scripts bedoelt om lokale omroepen te helpen met ANWB verkeer en NOS nieuws binnen te halen op een niet-Windows omgeving.
Hiermee word onder andere de 'NewsGo Downloader' van de ANWB vervangen.

Bij ZFM Zandvoort maken wij gebruik van de ANWB en NOS bulletins. Deze worden op een Linux machine binnen gehaald. Deze zet deze vervolgens klaar op een SMB share voor onze playout systemen.

Bijkomend kunnen beide scripts ook de audio normaliseren en witjes toe voegen aan het begin of einde van de bulletin. Dit is bij ons belangrijk wegens gebruik van het achterhaalde AIR2000, welke alleen op hele secondes kan knippen.

`nos.pl`
========

Dit is de NOS nieuws downloader. Er is een abonnement bij de NOS nodig (via de OLON) om het nieuws te mogen downloaden.
Belangrijk is dat deze pas op minuut 58 of later gedraaid wordt om aan de regels van de NOS te voldoen.

Configuration
-------------

```
# NOS server configuration
my $NOSBaseUrl = 'http://download.nos.nl/';

my $NOSUser = '<USERNAME>';
my $NOSPass = '<PASSWORD>';

<SNIP>

# audio options
my $normLevel  = '0';
my $padSeconds = '0 1';

# storage directory
my $outbox = '/mnt/news-traffic';
```

`$normLevel` is het aantal db onder 0dBFS.
`$padSeconds` is het aantal seconden voor en na de file, welke als witje toegevoegd worden.

Usage
-----

Alle 3 de bulletins welke het NOS beschikbaar stelt. Het script moet dan wel 3x gedraaid worden met andere parameters.

```
~ # nos.pl <nosnieuws.mp3|nosheadlines.mp3|nieuwsminuut.mpeg> [-v]
```

`-v` kan worden toegevoegd om debug output te krijgen.


`anwb.pl`
=========

Dit script vervangt de 'NewsGo Downloader'. Helaas is hier geen officiele documentatie van beschikbaar en is de code tot stand gekomen door het netwerk verkeer te analyseren.
Ook hier is weer een abonnement nodig, dit keer bij de ANWB, welke ook via de OLON geregeld kan worden.

Configuration
-------------

```
# ANWB server configuration
my @anwbServers = (
    '178.22.56.198',
    '87.233.213.245',
);

my $anwbUser = '<USERNAME>';
my $anwbPass = '<PASSWORD>';

<SNIP>

# audio options
my $normLevel  = '0';
my $padSeconds = '0 1';

# storage directory
my $outbox = '/mnt/news-traffic';
```

De opties zijn het zelfde als bij `nos.pl`.

Usage
-----

De server bied meestal 2 bulletins aan, de downloader zal de laatste downloaden en in de `$outbox` plaatsen.

```
~ # anwd.pl [-v]
```

`-v` kan worden toegevoegd om debug output te krijgen. Dit zal ook wat informatie weer geven over de bulletin.


Scheduling
==========

De scripts kunnen in crontab opgenomen worden om elk uur uit te laten voeren. Een voorbeeld van zo een crontab file vind je hier beneden.

```
~ # cat /etc/cron.d/news-downloader 
# Download news

# NOS radio nieuws (moet op minuut 58!)
58 * * * *  www-data    /opt/news-downloader/nos.pl nosnieuws.mp3
58 * * * *  www-data    /opt/news-downloader/nos.pl nosheadlines.mp3

# ANWB verkeer
5-59/10 * * * * www-data    /opt/news-downloader/anwb.pl

# NOS nieuws minuut video
*/30 * * * *    www-data    /opt/news-downloader/nos.pl nieuwsminuut.mpeg
```

