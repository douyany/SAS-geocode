# SAS-geocode
Add latitudes and longitudes (geocode) to a list of addresses and Calculate driving distance and time to a set of destination addresses


***This program takes a dataset with origin addresses;
***and sends them through the Google Maps API to get the driving distance (in miles);
***and driving time (in seconds);
***for 3 destination addresses;


***The address dataset that gets sent to proc geocode may need modification to fit the proc requirements and personal need;
***e.g., in the example file, all addresses are in Pennsylvania,;
***the state abbreviation (stabbr) is set to PA;


***The program is flexible to having fewer or more destination addresses;


***to modify for a different number of destination addresses:;

***a);
***change the 3 in;
***%do whichdest=1 %to 3;
***to your preferred number;

***b);
***add a %let destlat(number)=(latitude);
***for each destination up through your preferred number;

***c);
***add a %let destlong(number)=(longitude);
***for each destination up through your preferred number;

***d);
***in the merge,;
***you will want to add each file name individually;
***e.g., procedir.distance_time(number);
***for each destination up through your preferred number;

***e);
***in the merge,;
***you will want to add rename individually;
***e.g., (rename=(distance=distance_(nickname) time=time_(nickname));
***for each destination up through your preferred number;

***f);
***in the merge,;
***you will want to add each variable label individually;
***e.g., label distance_(nickname)="Distance to (nickname) in Miles";
***e.g., label time_(nickname)="Time to (nickname) in Seconds";
***for each destination up through your preferred number;

