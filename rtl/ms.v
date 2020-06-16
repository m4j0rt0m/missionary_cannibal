module ms(missionary_curr, cannibal_curr, direction, missionary_next, cannibal_next);

   //I/O declaration
   input[1:0]missionary_curr;
   input[1:0]cannibal_curr;
   input direction;
   output[1:0]missionary_next;
   output[1:0]cannibal_next;

   //inner net definition
   wire bc, ncnd, nbnce, cdne, nab, ane, acd, nce,ad,
   nbnc,dne,anb,cne,ncnde,ndne,cd,nabc,anbd;

   //primitive logic gate instantiation
   and (bc, missionary_curr[0],cannibal_curr[1]);//2-input and gate
   and (ncnd, ~cannibal_curr[1], ~cannibal_curr[0]);//2-input and gate
   and (nbnce, ~missionary_curr[0],~cannibal_curr[1], direction);//3-input and gate
   and (cdne, cannibal_curr[1], cannibal_curr[0], ~direction);//3-input and gate
   and (nab, ~missionary_curr[1], missionary_curr[0]);//2-input and gate
   and (ane, missionary_curr[1], ~direction);//2-input and gate
   and (acd, missionary_curr[1], cannibal_curr[1], cannibal_curr[0]);//3-input and gate
   and (nce, ~cannibal_curr[1], direction);//2-input and gate
   and (ad, missionary_curr[1], cannibal_curr[0]);//2-input and gate

   or w(missionary_next[1],bc, ncnd, nbnce, cdne, nab,ane,acd); //7-input and gate
   or x(missionary_next[0],bc, ncnd, nce, cdne, ane, ad);//6-input and gate

   //y
   and (nbnc, ~missionary_curr[0], ~cannibal_curr[1]);//2-input and gate
   and (dne, cannibal_curr[0], ~direction);//2-input and gate
   and (anb, missionary_curr[1], ~missionary_curr[0]);//2-input and gate
   and (cne, cannibal_curr[1], ~direction);//-input and gate

   and (ncnde, ~cannibal_curr[1], ~cannibal_curr[0], direction);//3-input and gate
   or y(cannibal_next[1],nbnc, dne, anb, cne, nab, ncnde);//6-input and gate
   //z
   and (ndne, ~cannibal_curr[0], ~direction);//2-input and gate

   and (cd, cannibal_curr[1], cannibal_curr[0]);//2-input and gate
   and (nabc, ~missionary_curr[1], missionary_curr[0], cannibal_curr[1]);//3-input and gate
   and (anbd, missionary_curr[1], ~missionary_curr[0], cannibal_curr[0]);//3-input and gate
   or z(cannibal_next[0], ndne, nce, cd, nabc, anbd);//5-input and gate
endmodule
