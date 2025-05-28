import 'package:flutter/services.dart';

class PhoneFormatter extends TextInputFormatter{
  
  // formatEditUpdate -> Es una clase que nos permite interceptar y modificar texto en el TextFormFiel
  @override
  TextEditingValue formatEditUpdate( TextEditingValue oldValue, TextEditingValue newValue) { // Se ejecuta cuando usuario introduce un valor


    String text = newValue.text.replaceAll(RegExp(r'\D'), ''); 
    String formatoText = '';

    for(int i = 0; i < text.length; i++){

      if( i  == 3){
        formatoText = '$formatoText ';
      } else if( i  == 6){
        formatoText = '$formatoText ';
      }
      if(i == 9){
        break;
      }
      formatoText += text[i];
    }

    return TextEditingValue(
      text: formatoText,
      selection: TextSelection.collapsed(offset: formatoText.length), // Mantiene cursos al final
    );
  }

}