#r "bin/Release/net10.0/PermitGenerated.dll"

let first, remaining = PermitGenerated.permit_claim true
let second, finalState = PermitGenerated.permit_claim remaining

if (first, remaining, second, finalState) <> (true, false, false, false) then
    failwithf "Unexpected permit transitions: %A" ((first, remaining), (second, finalState))
