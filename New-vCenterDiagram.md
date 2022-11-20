#  - ESXiHost Inventory

- [vCenter vCSA0010](#vcenter-vCSA0010)
- [vCenter vCSA0020](#vcenter-vCSA0020)
- [vCenter vCSA0021](#vcenter-vCSA0021)
- [vCenter vCSA0100](#vcenter-vCSA0100)
---

## [vCenter vCSA0010](https://vCSA0010.my.company.ch/ui)

---

````mermaid
classDiagram
VC1_vCSA0010 -- VC1C1_DMZPlatin01
VC1_vCSA0010 : + DMZPlatin01
VC1C1_DMZPlatin01 : + ProLiant XL170r Gen9
VC1C1_DMZPlatin01 -- VC1C1M1_ProLiant XL170r Gen9
VC1C1M1_ProLiant XL170r Gen9 -- VC1C1M1_Nord
VC1C1M1_Nord : + ESXi8201, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_Nord : + ESXi8202, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_Nord : + ESXi8218, ESXi 6.7, ProLiant XL170r Gen9
VC1C1M1_Nord : + ESXi8220, ESXi 6.7, ProLiant XL170r Gen9
VC1C1M1_ProLiant XL170r Gen9 -- VC1C1M1_West
VC1C1M1_West : + ESXi1201, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_West : + ESXi1202, ESXi 6.5, ProLiant XL170r Gen9
VC1C1M1_West : + ESXi1209, ESXi 6.7, ProLiant XL170r Gen9
VC1C1M1_West : + ESXi1220, ESXi 6.7, ProLiant XL170r Gen9
VC1_vCSA0010 -- VC1C2_FinPlatin01
VC1_vCSA0010 : + FinPlatin01
VC1C2_FinPlatin01 : + ProLiant XL170r Gen9
VC1C2_FinPlatin01 -- VC1C2M1_ProLiant XL170r Gen9
VC1C2M1_ProLiant XL170r Gen9 -- VC1C2M1_Nord
VC1C2M1_Nord : + ESXi8201, ESXi 6.5, ProLiant XL170r Gen9
VC1C2M1_Nord : + ESXi8202, ESXi 6.5, ProLiant XL170r Gen9
VC1C2M1_Nord : + ESXi8218, ESXi 6.7, ProLiant XL170r Gen9
VC1C2M1_Nord : + ESXi8220, ESXi 6.7, ProLiant XL170r Gen9
VC1C2M1_ProLiant XL170r Gen9 -- VC1C2M1_West
VC1C2M1_West : + ESXi1201, ESXi 6.5, ProLiant XL170r Gen9
VC1C2M1_West : + ESXi1202, ESXi 6.5, ProLiant XL170r Gen9
VC1C2M1_West : + ESXi1209, ESXi 6.7, ProLiant XL170r Gen9
VC1C2M1_West : + ESXi1220, ESXi 6.7, ProLiant XL170r Gen9
VC1_vCSA0010 -- VC1C3_zDMZTransfer
VC1_vCSA0010 : + z-DMZ-Transfer
VC1C3_zDMZTransfer : + XH620 V3
VC1C3_zDMZTransfer -- VC1C3M1_XH620 V3
VC1C3M1_XH620 V3 -- VC1C3M1_West
VC1C3M1_West : + ESXi1994, ESXi 6.7, XH620 V3
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
VC2C1M1_ProLiant DL380 Gen10 -- VC2C1M1_Nord
VC2C1M1_Nord : + ESXi8901, ESXi 6.7 6.7, ProLiant DL380 Gen10
VC2C1M1_Nord : + ESXi8903, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_ProLiant DL380 Gen10 -- VC2C1M1_Ost
VC2C1M1_Ost : + ESXi7902, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_Ost : + ESXi7903, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_Ost : + ESXi7904, ESXi 6.7, ProLiant DL380 Gen10
VC2C1M1_ProLiant DL380 Gen10 -- VC2C1M1_West
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
VC3C1M1_ProLiant DL380 Gen10 -- VC3C1M1_Nord
VC3C1M1_Nord : + ESXi8911, ESXi 6.7, ProLiant DL380 Gen10
VC3C1M1_ProLiant DL380 Gen10 -- VC3C1M1_Ost
VC3C1M1_Ost : + ESXi7912, ESXi 6.7, ProLiant DL380 Gen10
````

[Top](#)

---

## [vCenter vCSA0100](https://vCSA0100.my.company.ch/ui)

---

````mermaid
classDiagram
VC4_vCSA0100 -- VC4C1_c4tn9070
VC4_vCSA0100 : + c4tn9070
VC4C1_c4tn9070 : + Synergy 480 Gen10
VC4C1_c4tn9070 -- VC4C1M1_Synergy 480 Gen10
VC4C1M1_Synergy 480 Gen10 -- VC4C1M1_Nord
VC4C1M1_Nord : + ESXi8051, ESXi 7.0.3, Synergy 480 Gen10
VC4C1M1_Nord : + ESXi8052, ESXi 7.0.3 7.0.3, Synergy 480 Gen10
VC4C1M1_Synergy 480 Gen10 -- VC4C1M1_Ost
VC4C1M1_Ost : + ESXi7051, ESXi 7.0.3, Synergy 480 Gen10
VC4_vCSA0100 -- VC4C2_c8tn6989
VC4_vCSA0100 : + c8tn6989
VC4C2_c8tn6989 : + ProLiant DL380 Gen9
VC4C2_c8tn6989 -- VC4C2M1_ProLiant DL380 Gen9
VC4C2M1_ProLiant DL380 Gen9 -- VC4C2M1_Nord
VC4C2M1_Nord : + ESXi8998, ESXi 7.0.3, ProLiant DL380 Gen9
VC4C2M1_ProLiant DL380 Gen9 -- VC4C2M1_Ost
VC4C2M1_Ost : + ESXi7999, ESXi 7.0.3, ProLiant DL380 Gen9
````

[Top](#)

---

I ♥ PS > Diagram created with PowerShell and Mermaid at 20.11.2022 13:25:30

---
