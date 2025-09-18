import 'package:flutter/material.dart';

// Этот класс-художник умеет рисовать волну внизу экрана.
class BottomWaveClipper extends CustomClipper<Path> {
  
  // Вот здесь было изменение!
  // Flutter ищет метод с именем "getClip", чтобы понять, как рисовать.
  // БЫЛО: Path getPath(Size size) {
  // СТАЛО:
  @override
  Path getClip(Size size) {
    // Начинаем рисовать. Path - это наш виртуальный карандаш.
    var path = Path();
    
    // Карандаш начинает с левого края, но не с самого низа.
    path.lineTo(0, size.height * 0.8);

    // Рисуем первую кривую волны до середины экрана.
    path.quadraticBezierTo(
      size.width / 4,       // Контрольная точка по горизонтали
      size.height * 0.7,    // Контрольная точка по вертикали (изгиб вверх)
      size.width / 2,       // Конец кривой - середина экрана
      size.height * 0.85,    // Конечная точка по вертикали
    );

    // Рисуем вторую кривую волны до правого края экрана.
    path.quadraticBezierTo(
      size.width * 3 / 4,   // Контрольная точка по горизонтали
      size.height,          // Контрольная точка по вертикали (изгиб вниз)
      size.width,           // Конец кривой - правый край экрана
      size.height * 0.9,    // Конечная точка по вертикали
    );
    
    // Ведем линию до правого нижнего угла.
    path.lineTo(size.width, size.height);
    // Ведем линию до левого нижнего угла.
    path.lineTo(0, size.height);
    // Замыкаем контур, чтобы фигуру можно было закрасить.
    path.close();

    return path;
  }

  // Этот метод говорит Flutter'у, что волну не нужно перерисовывать,
  // если размеры виджета не изменились. Это экономит ресурсы.
  // Он был правильным, его не трогаем.
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}