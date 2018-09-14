import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _ultimoRemovido;
  int _posicaoRemovido;


  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["title"] = _toDoController.text;
      _toDoController.text = "";
      novaTarefa["ok"] = false;
      _toDoList.add(novaTarefa);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1)); //Manten 1 segundo o refresh da tela para um efeito mais bacana
    setState(() {
      _toDoList.sort((ant, post){
        if(ant["ok"] && !post["ok"]) return 1;
        else if(!ant["ok"] && post["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  decoration: InputDecoration(
                    labelText: "Nova Tarefa",
                    labelStyle: TextStyle(color: Colors.blueAccent),
                  ),
                  controller: _toDoController,
                )),
                RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed: _addToDo),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: criaItem,
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget criaItem(context, index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.clear),
        ),
        onChanged: (concluido) {
          setState(() {
            _toDoList[index]["ok"] = concluido;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _ultimoRemovido = Map.from(_toDoList[index]);
          _posicaoRemovido = index;
          _toDoList.removeAt(index);

          _saveData();
          
          final snack = SnackBar(
              content: Text("Tarefa ${_ultimoRemovido["title"]} removida!"),
              action: SnackBarAction(label: "Desfazer", 
                  onPressed: (){
                    setState(() {
                      _toDoList.insert(_posicaoRemovido, _ultimoRemovido);
                      _saveData();
                    });
                  }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.jason");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
