import 'package:flutter/material.dart';
import 'package:flutter_application_projeto_integrador/ong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InfoOng extends StatefulWidget {
  const InfoOng({super.key});

  @override
  State<InfoOng> createState() => _InfoOngState();
}

class _InfoOngState extends State<InfoOng> {
  List<Ong> listaOng = [];

  @override
  void initState() {
    super.initState();
    buscarBD();
  }

  Future<void> buscarBD() async {
    var url = Uri.parse('http://localhost:8080/apiOng/todos');
    http.Response response = await http.get(url);
    if (response.statusCode == 200) {
      List lista = jsonDecode(response.body) as List;

      listaOng = lista.map((json) => Ong.fromJson(json)).toList();
      setState(() {});
    } else {
      print('Erro ao carregar dados');
    }
  }

  Future<void> excluirOng(int index) async {
    var url = Uri.parse(
        'http://localhost:8080/apiOng/excluir/${listaOng[index].cnpj}');
    http.Response response = await http.delete(url);
    if (response.statusCode == 200) {
      setState(() {
        listaOng.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ONG excluída com sucesso!")),
      );
    } else {
      print('Erro ao excluir ONG');
    }
  }

  void confirmarExclusao(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar Exclusão"),
          content: Text("Tem certeza que deseja excluir esta ONG?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Excluir"),
              onPressed: () {
                Navigator.of(context).pop();
                excluirOng(index);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro de ONGs"),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: listaOng.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color.fromARGB(255, 1, 37, 54),
                          child: Text(
                            listaOng[index].nome[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(listaOng[index].nome.toString()),
                        subtitle: Text(listaOng[index].email.toString()),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Color.fromARGB(255, 1, 37, 54),
                          ),
                          onPressed: () {
                            confirmarExclusao(index);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.blueGrey,
    );
  }
}
