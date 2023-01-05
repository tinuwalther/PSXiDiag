# Markdown ESXiHost Inventory

 - [vCenter vCSA010](#vcenter-vcsa010)
 - [vCenter vCSA020](#vcenter-vcsa020)
 - [vCenter vCSA021](#vcenter-vcsa021)
 - [vCenter vCSA100](#vcenter-vcsa100)
---

## [vCenter vCSA010](https://vCSA010.my.company.ch/ui)

---

````mermaid
classDiagram
VC1_vCSA010 -- VC1C1_Linux
VC1_vCSA010 : + Linux
VC1C1_Linux : + ProLiant XL170r Gen9
VC1C1_Linux -- VC1C1_ProLiant XL170r Gen9
VC1C1_ProLiant XL170r Gen9 : - Nord, 2 ESXi Hosts
VC1C1_ProLiant XL170r Gen9 -- VC1C1_Nord
VC1C1_Nord : + ESXi8201, ESXi 6.5, ProLiant XL170r Gen9
VC1C1_Nord : + ESXi8202, ESXi 6.5, ProLiant XL170r Gen9
VC1C1_ProLiant XL170r Gen9 : - West, 2 ESXi Hosts
VC1C1_ProLiant XL170r Gen9 -- VC1C1_West
VC1C1_West : + ESXi1201, ESXi 6.5, ProLiant XL170r Gen9
VC1C1_West : + ESXi1202, ESXi 6.5, ProLiant XL170r Gen9
VC1_vCSA010 -- VC1C2_Transfer
VC1_vCSA010 : + Transfer
VC1C2_Transfer : + XH620 V3
VC1C2_Transfer -- VC1C2_XH620 V3
VC1C2_XH620 V3 : - West, 1 ESXi Hosts
VC1C2_XH620 V3 -- VC1C2_West
VC1C2_West : + ESXi1994, ESXi 6.7, XH620 V3
VC1_vCSA010 -- VC1C3_Windows
VC1_vCSA010 : + Windows
VC1C3_Windows : + ProLiant XL170r Gen9
VC1C3_Windows -- VC1C3_ProLiant XL170r Gen9
VC1C3_ProLiant XL170r Gen9 : - Nord, 1 ESXi Hosts
VC1C3_ProLiant XL170r Gen9 -- VC1C3_Nord
VC1C3_Nord : + ESXi8220, ESXi 6.7, ProLiant XL170r Gen9
VC1C3_ProLiant XL170r Gen9 : - West, 1 ESXi Hosts
VC1C3_ProLiant XL170r Gen9 -- VC1C3_West
VC1C3_West : + ESXi1220, ESXi 6.7, ProLiant XL170r Gen9
VC1C3_Windows : + Synergy 480 Gen10
VC1C3_Windows -- VC1C3_Synergy 480 Gen10
VC1C3_Synergy 480 Gen10 : - Nord, 1 ESXi Hosts
VC1C3_Synergy 480 Gen10 -- VC1C3_Nord
VC1C3_Nord : o ESXi8218, ESXi 6.7, Synergy 480 Gen10
VC1C3_Synergy 480 Gen10 : - West, 1 ESXi Hosts
VC1C3_Synergy 480 Gen10 -- VC1C3_West
VC1C3_West : o ESXi1209, ESXi 6.7, Synergy 480 Gen10
````

[Top](#)

---

## [vCenter vCSA020](https://vCSA020.my.company.ch/ui)

---

````mermaid
classDiagram
VC2_vCSA020 -- VC2C1_Oracle
VC2_vCSA020 : + Oracle
VC2C1_Oracle : + ProLiant DL380 Gen10
VC2C1_Oracle -- VC2C1_ProLiant DL380 Gen10
VC2C1_ProLiant DL380 Gen10 : - Nord, 2 ESXi Hosts
VC2C1_ProLiant DL380 Gen10 -- VC2C1_Nord
VC2C1_Nord : + ESXi8901, ESXi 6.7, ProLiant DL380 Gen10
VC2C1_Nord : + ESXi8903, ESXi 6.7, ProLiant DL380 Gen10
VC2C1_ProLiant DL380 Gen10 : - Ost, 2 ESXi Hosts
VC2C1_ProLiant DL380 Gen10 -- VC2C1_Ost
VC2C1_Ost : + ESXi7902, ESXi 6.7, ProLiant DL380 Gen10
VC2C1_Ost : + ESXi7903, ESXi 6.7, ProLiant DL380 Gen10
VC2C1_ProLiant DL380 Gen10 : - West, 2 ESXi Hosts
VC2C1_ProLiant DL380 Gen10 -- VC2C1_West
VC2C1_West : + ESXi1204, ESXi 6.7, ProLiant DL380 Gen10
VC2C1_West : + ESXi1902, ESXi 6.7, ProLiant DL380 Gen10
````

[Top](#)

---

## [vCenter vCSA021](https://vCSA021.my.company.ch/ui)

---

````mermaid
classDiagram
VC3_vCSA021 -- VC3C1_Oracle
VC3_vCSA021 : + Oracle
VC3C1_Oracle : + ProLiant DL380 Gen10
VC3C1_Oracle -- VC3C1_ProLiant DL380 Gen10
VC3C1_ProLiant DL380 Gen10 : - Nord, 1 ESXi Hosts
VC3C1_ProLiant DL380 Gen10 -- VC3C1_Nord
VC3C1_Nord : + ESXi8911, ESXi 6.7, ProLiant DL380 Gen10
VC3C1_ProLiant DL380 Gen10 : - Ost, 1 ESXi Hosts
VC3C1_ProLiant DL380 Gen10 -- VC3C1_Ost
VC3C1_Ost : + ESXi7912, ESXi 6.7, ProLiant DL380 Gen10
````

[Top](#)

---

## [vCenter vCSA100](https://vCSA100.my.company.ch/ui)

---

````mermaid
classDiagram
VC4_vCSA100 -- VC4C1_Linux
VC4_vCSA100 : + Linux
VC4C1_Linux : + Synergy 480 Gen10
VC4C1_Linux -- VC4C1_Synergy 480 Gen10
VC4C1_Synergy 480 Gen10 : - Nord, 3 ESXi Hosts
VC4C1_Synergy 480 Gen10 -- VC4C1_Nord
VC4C1_Nord : + ESXi8051, ESXi 7.0.3, Synergy 480 Gen10
VC4C1_Nord : + ESXi8052, ESXi 7.0.3, Synergy 480 Gen10
VC4C1_Nord : + ESXi8053, ESXi 7.0.3, Synergy 480 Gen10
VC4C1_Synergy 480 Gen10 : - Ost, 1 ESXi Hosts
VC4C1_Synergy 480 Gen10 -- VC4C1_Ost
VC4C1_Ost : + ESXi7051, ESXi 7.0.3, Synergy 480 Gen10
VC4_vCSA100 -- VC4C2_Windows
VC4_vCSA100 : + Windows
VC4C2_Windows : + ProLiant DL380 Gen9
VC4C2_Windows -- VC4C2_ProLiant DL380 Gen9
VC4C2_ProLiant DL380 Gen9 : - Nord, 1 ESXi Hosts
VC4C2_ProLiant DL380 Gen9 -- VC4C2_Nord
VC4C2_Nord : + ESXi8998, ESXi 7.0.3, ProLiant DL380 Gen9
VC4C2_ProLiant DL380 Gen9 : - Ost, 1 ESXi Hosts
VC4C2_ProLiant DL380 Gen9 -- VC4C2_Ost
VC4C2_Ost : + ESXi7999, ESXi 7.0.3, ProLiant DL380 Gen9
````

[Top](#)

---

I ♥ PS > Diagram created with PowerShell and Mermaid at 05.01.2023 19:20:29

---
