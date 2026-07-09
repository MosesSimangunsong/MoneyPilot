# Indonesian Number Parser Rules

## Format Angka yang Harus Didukung MVP

| Input | Output |
|---|---:|
| 15000 | 15000 |
| 15.000 | 15000 |
| 15,000 | 15000 |
| 15 ribu | 15000 |
| 15 rb | 15000 |
| 15k | 15000 |
| dua puluh lima ribu | 25000 |
| seratus ribu | 100000 |
| lima ratus ribu | 500000 |
| satu juta | 1000000 |
| 1 juta | 1000000 |
| 1,5 juta | 1500000 |
| setengah juta | 500000 |

## Kata Bilangan Dasar

nol = 0  
satu = 1  
dua = 2  
tiga = 3  
empat = 4  
lima = 5  
enam = 6  
tujuh = 7  
delapan = 8  
sembilan = 9  
sepuluh = 10  
sebelas = 11  

## Skala

ribu = 1000  
juta = 1000000  

## Unit Test Minimal

- parse 25 ribu = 25000
- parse dua puluh lima ribu = 25000
- parse 1 juta = 1000000
- parse setengah juta = 500000
- parse 25k = 25000
- parse 25 rb = 25000