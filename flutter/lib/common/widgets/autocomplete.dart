import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import '../../../models/platform_model.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';


 Future<List<Peer>> getAllPeers() async {
    Map<String, dynamic> recentPeers = jsonDecode(await bind.mainLoadRecentPeersSync());
    Map<String, dynamic> lanPeers = jsonDecode(await bind.mainLoadLanPeersSync());
    Map<String, dynamic> abPeers = jsonDecode(await bind.mainLoadAbSync());
    Map<String, dynamic> groupPeers = jsonDecode(await bind.mainLoadGroupSync());

    Map<String, dynamic> combinedPeers = {};

    void _mergePeers(Map<String, dynamic> peers) {
      if (peers.containsKey("peers")) {
        dynamic peerData = peers["peers"];

        if (peerData is String) {
          try {
            peerData = jsonDecode(peerData);
          } catch (e) {
            print("Error decoding peers: $e");
            return;
          }
        }

        if (peerData is List) {
          for (var peer in peerData) {
            if (peer is Map && peer.containsKey("id")) {
              String id = peer["id"];
              if (id != null && !combinedPeers.containsKey(id)) {
                combinedPeers[id] = peer;
              }
            }
          }
        }
      }
    }

    _mergePeers(recentPeers);
    _mergePeers(lanPeers);
    _mergePeers(abPeers);
    _mergePeers(groupPeers);

      List<Peer> parsedPeers = [];

    for (var peer in combinedPeers.values) {
      parsedPeers.add(Peer.fromJson(peer));
    }
    return  parsedPeers;
  }

 class AutocompletePeerTile extends StatefulWidget {
  final IDTextEditingController idController;
  final Peer peer;

  const AutocompletePeerTile({
    Key? key,
    required this.idController,
    required this.peer,
  }) : super(key: key);

  @override
  _AutocompletePeerTileState createState() => _AutocompletePeerTileState();
}

class _AutocompletePeerTileState extends State<AutocompletePeerTile>{
  List _frontN<T>(List list, int n) {
    if (list.length <= n) {
      return list;
    } else {
      return list.sublist(0, n);
    }
  }
  @override
  Widget build(BuildContext context){
    final double _tileRadius = 5;
        final name =
          '${widget.peer.username}${widget.peer.username.isNotEmpty && widget.peer.hostname.isNotEmpty ? '@' : ''}${widget.peer.hostname}';
        final greyStyle = TextStyle(
          fontSize: 11,
          color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.6));
        final child = GestureDetector(
          onTap: () {
            setState(() {
              widget.idController.id = widget.peer.id;
              FocusScope.of(context).unfocus();
            });
          },
          child:
        Container(
          height: 42,
          margin: EdgeInsets.only(bottom: 5),
          child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              decoration: BoxDecoration(
                color: str2color('${widget.peer.id}${widget.peer.platform}', 0x7f),
                borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_tileRadius),
                        bottomLeft: Radius.circular(_tileRadius),
                      ),
              ),
              alignment: Alignment.center,
              width: 42,
              height: null,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: getPlatformImage(widget.peer.platform, size: 30)
              )
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(_tileRadius),
                    bottomRight: Radius.circular(_tileRadius),
                  ),
                ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 2),
                    child: Container(
                      margin: EdgeInsets.only(top: 2),
                      child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 2),
                        child: Row(children: [
                          getOnline(8, widget.peer.online),
                          Expanded(
                              child: Text(
                            widget.peer.alias.isEmpty ? formatID(widget.peer.id) : widget.peer.alias,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          )),
                          !widget.peer.alias.isEmpty?
                          Padding(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: Text(
                              "(${widget.peer.id})",
                              style: greyStyle,
                              overflow: TextOverflow.ellipsis,
                            )
                          )
                          : Container(),
                      ])),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          name,
                          style: greyStyle,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                ))),
              ],
            )
            ),
        )
      ],
    )));
    final colors =
        _frontN(widget.peer.tags, 25).map((e) => gFFI.abModel.getTagColor(e)).toList();
    return Tooltip(
      message: isMobile
          ? ''
          : widget.peer.tags.isNotEmpty
              ? '${translate('Tags')}: ${widget.peer.tags.join(', ')}'
              : '',
      child: Stack(children: [
        child,
        if (colors.isNotEmpty)
          Positioned(
            top: 5,
            right: 10,
            child: CustomPaint(
              painter: TagPainter(radius: 3, colors: colors),
            ),
          )
      ]),
    );
  }
  }