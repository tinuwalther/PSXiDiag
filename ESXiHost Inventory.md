#  - ESXiHost Inventory

 - [vCenter vCSA0010](#vcenter-vcsa0010)
 - [vCenter vCSA0020](#vcenter-vcsa0020)
 - [vCenter vCSA0021](#vcenter-vcsa0021)
 - [vCenter vCSA0100](#vcenter-vcsa0100)
---

## [vCenter vCSA0010](https://vCSA0010.my.company.ch/ui)

---

````mermaid
classDiagram
VC1_vCSA0010 -- VC1C1_Linux
VC1_vCSA0010 : + Linux
VC1C1_Linux : + ProLiant XL170r Gen9
VC1C1_Linux -- VC1C1M1_ProLiant XL170r Gen9
VC1C1M1_ProLiant XL170r Gen9 : - Nord
VC1C1M1_ProLiant XL170r Gen9 -- VC1C1M1_Nord
VC1C1M1_Nord : + ESXi8201, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_Nord : + ESXi8202, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_ProLiant XL170r Gen9 : - West
VC1C1M1_ProLiant XL170r Gen9 -- VC1C1M1_West
VC1C1M1_West : + ESXi1201, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_West : + ESXi1202, ESXi 6.5, ProLiant XL170r Gen9
VC1_vCSA0010 -- VC1C2_Transfer
VC1_vCSA0010 : + Transfer
VC1C2_Transfer : + XH620 V3
VC1C2_Transfer -- VC1C2M1_XH620 V3
VC1C2M1_XH620 V3 : - West
VC1C2M1_XH620 V3 -- VC1C2M1_West
VC1C2M1_West : o ESXi1994, ESXi 6.7, XH620 V3
VC1_vCSA0010 -- VC1C3_Windows
VC1_vCSA0010 : + Windows
VC1C3_Windows : + ProLiant XL170r Gen9
VC1C3_Windows -- VC1C3M1_ProLiant XL170r Gen9
VC1C3M1_ProLiant XL170r Gen9 : - Nord
VC1C3M1_ProLiant XL170r Gen9 -- VC1C3M1_Nord
VC1C3M1_Nord : + ESXi8218, ESXi 6.7, ProLiant XL170r Gen9
VC1C3M1_Nord : + ESXi8220, ESXi 6.7, ProLiant XL170r Gen9
VC1C3M1_ProLiant XL170r Gen9 : - West
VC1C3M1_ProLiant XL170r Gen9 -- VC1C3M1_West
VC1C3M1_West : + ESXi1209, ESXi 6.7, ProLiant XL170r Gen9
VC1C3M1_West : + ESXi1220, ESXi 6.7, ProLiant XL170r Gen9
````

[Top](#)

---

## [vCenter vCSA0020](https://vCSA0020.my.company.ch/ui)

---

````mermaid
classDiagram
VC2_vCSA0020 -- VC2C1_Oracle
VC2_vCSA0020 : + Oracle
VC2C1_Oracle : + ProLiant DL380 Gen10
VC2C1_Oracle -- VC2C1M1_ProLiant DL380 Gen10
VC2C1M1_ProLiant DL380 Gen10 : - Nord
VC2C1M1_ProLiant DL380 Gen10 -- VC2C1M1_Nord
VC2C1M1_Nord : + ESXi8901, ESXi 6.7 6.7, ProLiant DL380 Gen10
VC2C1M1_Nord : + ESXi8903, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_ProLiant DL380 Gen10 : - Ost
VC2C1M1_ProLiant DL380 Gen10 -- VC2C1M1_Ost
VC2C1M1_Ost : + ESXi7902, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_Ost : + ESXi7903, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_ProLiant DL380 Gen10 : - West
VC2C1M1_ProLiant DL380 Gen10 -- VC2C1M1_West
VC2C1M1_West : + ESXi1204, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_West : + ESXi1902, ESXi 6.7, ProLiant DL380 Gen10
````

[Top](#)

---

## [vCenter vCSA0021](https://vCSA0021.my.company.ch/ui)

---

````mermaid
classDiagram
VC3_vCSA0021 -- VC3C1_Oracle
VC3_vCSA0021 : + Oracle
VC3C1_Oracle : + ProLiant DL380 Gen10
VC3C1_Oracle -- VC3C1M1_ProLiant DL380 Gen10
VC3C1M1_ProLiant DL380 Gen10 : - Nord
VC3C1M1_ProLiant DL380 Gen10 -- VC3C1M1_Nord
VC3C1M1_Nord : + ESXi8911, ESXi 6.7, ProLiant DL380 Gen10
VC3C1M1_ProLiant DL380 Gen10 : - Ost
VC3C1M1_ProLiant DL380 Gen10 -- VC3C1M1_Ost
VC3C1M1_Ost : + ESXi7912, ESXi 6.7, ProLiant DL380 Gen10
````

[Top](#)

---

## [vCenter vCSA0100](https://vCSA0100.my.company.ch/ui)

---

````mermaid
classDiagram
VC4_vCSA0100 -- VC4C1_Linux
VC4_vCSA0100 : + Linux
VC4C1_Linux : + Synergy 480 Gen10
VC4C1_Linux -- VC4C1M1_Synergy 480 Gen10
VC4C1M1_Synergy 480 Gen10 : - Nord
VC4C1M1_Synergy 480 Gen10 -- VC4C1M1_Nord
VC4C1M1_Nord : + ESXi8051, ESXi 7.0.3, Synergy 480 Gen10
VC4C1M1_Nord : + ESXi8052, ESXi 7.0.3 7.0.3, Synergy 480 Gen10
VC4C1M1_Synergy 480 Gen10 : - Ost
VC4C1M1_Synergy 480 Gen10 -- VC4C1M1_Ost
VC4C1M1_Ost : + ESXi7051, ESXi 7.0.3, Synergy 480 Gen10
VC4_vCSA0100 -- VC4C2_Windows
VC4_vCSA0100 : + Windows
VC4C2_Windows : + ProLiant DL380 Gen9
VC4C2_Windows -- VC4C2M1_ProLiant DL380 Gen9
VC4C2M1_ProLiant DL380 Gen9 : - Nord
VC4C2M1_ProLiant DL380 Gen9 -- VC4C2M1_Nord
VC4C2M1_Nord : + ESXi8998, ESXi 7.0.3, ProLiant DL380 Gen9
VC4C2M1_ProLiant DL380 Gen9 : - Ost
VC4C2M1_ProLiant DL380 Gen9 -- VC4C2M1_Ost
VC4C2M1_Ost : + ESXi7999, ESXi 7.0.3, ProLiant DL380 Gen9
````

[Top](#)

---

I ♥ PS > Diagram created with PowerShell and Mermaid at 21.11.2022 20:28:03

---
