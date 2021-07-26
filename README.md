# Reed Solomon Encoder
A Reed-Solomon encoder using an 8-bit word size. `k` is parameterized. `n` is
based on the word size, so is always 255, but is also parameterized, so that it
could use a different word size

It is a lightly modified version of the Reed-Solomon encoder given here:
https://surf-vhdl.com/how-to-implement-a-reed-solomon-encoder-in-vhdl/

with the 8-bit Galois multiplier from: 
https://surf-vhdl.com/how-to-implement-a-reed-solomon-encoder-in-vhdl/
