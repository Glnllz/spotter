import 'package:flutter/material.dart';

// Это наш главный цвет для кнопок и волн.
const Color primaryColor = Color(0xFF6ACC8B); 

// Это цвет фона наших страниц.
const Color backgroundColor = Color(0xFFF8F8F6);

// Это цвет текста.
const Color textColor = Color(0xFF333333);

// Это стиль для больших заголовков, как "WELCOME".
const TextStyle headerTextStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: textColor,
  letterSpacing: 1.5, // Расстояние между буквами
);

// Это стиль для текста внутри полей ввода.
const InputDecoration formInputDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(30.0)),
    borderSide: BorderSide.none, // Убираем рамку по умолчанию
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(30.0)),
    borderSide: BorderSide(color: Colors.grey, width: 1.5), // Серая рамка
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(30.0)),
    borderSide: BorderSide(color: primaryColor, width: 2.0), // Зеленая рамка при нажатии
  ),
);