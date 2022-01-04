from asyncio.queues import Queue

class Message:
    def __init__(self):
        pass
class Peer:
    def __init__(self):
        pass
class Peers:
    def __init__(self):
        self.peers=[]
        pass
class Node:
    def __init__(self, peer=None, name='Unknown'):
        self.peer = peer
        self.name = name
        pass

class asyncClass:
    def __init__(self, loop):
        self.__loop = loop
        pass
class NetworkLayer1(asyncClass):
    """
    packet level, operates MAc address
    """
    def __init__(self, loop):
        super().__init__(loop)
        self.__sendqueue=Queue()
        self.__sendqueue=Queue()
        self.__loop = loop
        pass
    def sendPacket(self, mac, packet):
        pass
    def receivePacket(self):
        pass
    def run(self):
        pass
class NetworkLayer2(asyncClass):
    """
    message level, operates NodeNames, without routing
    """
    def __init__(self, loop):
        super().__init__(loop)
        self.__peers=Peers()
        pass
    def sendMessage(self):
        pass
    def receiveMessage(self):
        pass
class NetworkLayer3(asyncClass):
    """
    message level, operates NodeNames, WITH routing
    """
    def __init__(self, loop):
        super().__init__(loop)
        pass


