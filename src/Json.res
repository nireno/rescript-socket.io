/* @Performance
     ~~Special serialization logic because we cannot serialize variants using Json.stringify.
     The reason for that is that Variants are represented as arrays under the hood with a property .tag
     representing the tag kind. That property isn't one that's normally on array so Json.stringify won't serialize it.
     We have to resort to using our own encoding.  Ben - July 24 2017 ~~

     In Rescript, special serialization is no longer required for variants as was discussed above for 
     the Bucklescript version.
 */
let toValidJson = %raw(`  
(o) => {
  switch (typeof o){
    case "boolean":
    case "number":
    case "string":
      return o;
    case "function":
      throw new Error("Cannot serialize functions");
    case "object":
      return JSON.stringify(o);
  }
}
`)

let fromValidJson = %raw(` 
(o) => {
  switch (typeof o){
    case "boolean":
    case "number":
    case "string":
      return o;
    case "function":
      throw new Error("Cannot deserialize functions");
    case "object":
      return JSON.parse(o);
  }
}
`)
