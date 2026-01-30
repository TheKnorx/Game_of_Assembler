# GameOfLive_ASM
Game of life in assembly
## Usage: 
`main <field-width> <field-height> <amount of generations>`<br>
Note that both, the width and the height, ARE NOT to exceed 4 bytes in size and the multiplication of them also SHOULD NOT exceed 4 bytes in size<br>
Bigger width and field sizes cause undefined behavior. Additionally note that if the multiplication (=field area) of them exceeds 4 bytes, we modify the value with: `2^32 mod <result>`. Just like the behavior of a C-style int variable on overflow.  

# Code Conventions:
## Function calls
* Every function call uses the `x84-64 System V ABI calling convention` for parameter passing, as well as for returning return values
* Every function is preceeded with at least one comment specifying the exact parameters to pass into and the exact return value it returns with in the form of `(<parameters>)[<return values>]` like so:<br>
  `(listOf[<C-type> <purpose-tag> @ <register/address>, ...])[<C-type> <purpose-tag> @ <register/address>]` <br>
  Additional comments ... yea. maybe
## Stack
* The stack of each function is aligned as `mod 16`. We do this by using this special stack alignment prolog:
  ```asm
  push    rbp
  mov     rbp, rsp
  and     rsp, -16
  ```
  \(For the haters and/or lovers of steal-clean assembly - i dont care and see x64 Assembly Language by Jeff Duntemann: chapter 12 - stack alignment)<br>
  (For the people who are missing the `enter` instruction, see [here](https://stackoverflow.com/a/5964507) why)
