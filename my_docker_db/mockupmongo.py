from mockupdb import *
import mockupdb
from collections import OrderedDict
import sys
import json
from bson.int64 import Int64
import time
import os
import re
import base64
import dateutil.parser
import traceback
import logging

numbers = re.compile(r'(\d+)')

#Ordinamento per lettura file da cartella
def numericalSort(value):
    parts = numbers.split(value)
    parts[1::2] = map(int, parts[1::2])
    return parts

#Controllo campi principali di una richiesta
    #test_req contiene la richiesta di confronto
    #req contiene la richiesta da confrontare
    #field contiene il campo da controllare
def check_field(test_req,req,field):
    if field in test_req and field in req:
        if not (test_req[field] == req[field]):
            return False
    else:
        if field in test_req or field in req:
            return False
    return True

#Controllo dei dizionari estratti come elementi dei campi delle richieste
    #dict_check contiene dizionario elemento della richiesta di confronto
    #dict_data contiene dizionario elemento della richiesta da confrontare
def check_dict(dict_check,dict_data):
    if not len(dict_check) == len(dict_data):
        print("non contengono lo stesso numero di elementi")
        return False
    for key, value in dict_check.items():
        if not key in dict_data:
            print("non contengono gli stessi elementi")
            return False
        if key != 'id' and key != '_id':
            if value != dict_data[key]:
                print("non corrispondono")
                return False
    return True


#Controllo comando Delete
    #test_req contiene la richiesta di confronto
    #req contiene la richiesta da confrontare
def cmd_delete(test_req,req):
    #Controllo campo Delete
    if not check_field(test_req,req,'delete'):
        print("campi delete dei comandi delete non corrispondono")
        return False
    #Controllo campo Deletes ---- array di dict
    if 'deletes' in test_req and 'deletes' in req:
        lung = len(test_req['deletes'])
        if lung != len(req['deletes']):
            print("campi deletes con diverso numero di elementi")
            return False
        for i in range(0,lung-1):
            deletes_check = test_req['deletes'][i]
            deletes = req['deletes'][i]
            if not check_dict(deletes_check, deletes):
                print("elementi campi deletes non corrispondendi")
                return False
    else:
        # Nella nuova versione di mongo mongreplay mette la parte di deletes dentro a documents e identifier identifica
        # il comando
        if 'identifier' in test_req and test_req['identifier'] == 'deletes' and 'deletes' in req:
            lung = len(test_req['documents'])
            if lung != len(req['deletes']):
                print("campi deletes con diverso numero di elementi")
                return False
            for i in range(0, lung - 1):
                deletes_check = test_req['documents'][i]
                deletes = req['deletes'][i]
                if not check_dict(deletes_check, deletes):
                    print("elementi campi deletes non corrispondendi")
                    return False
        # Controllo che almeno uno abbia il campo
        # Altrimenti se entrambi non lo hanno non è da considerare un errore
        if 'deletes' in test_req or 'deletes' in req or ('identifier' in test_req and test_req['identifier'] == 'deletes'):
            print("campi deletes non presenti in entrambe le request")
            return False
    # Controllo campo ordered ---- bool ---to lower case
    if 'ordered' in test_req and 'ordered' in req:
        if not (str(test_req['ordered']).lower() == str(req['ordered']).lower()):
            print("campi ordered di comandi delete non corrispondono")
            return False
    else:
        if 'ordered' in test_req or 'ordered' in req:
            print("campi ordered di comandi delete non presenti in entrambe le richieste")
            return False
    return True

#Controllo comando Update
    #test_req contiene la richiesta di confronto ( da file )
    #req contiene la richiesta da confrontare ( ricevuta )
def cmd_update(test_req,req):
    #Controllo campo Update
    if not check_field(test_req,req,'update'):
        print("campi update dei comandi update non corrispondono")
        return False
    print("da file: "+str(test_req))
    print("da comando: "+str(req))
    #Controllo campo Updates ---- array di dict
    if 'updates' in test_req and 'updates' in req:
        lung = len(test_req['updates'])
        if lung != len(req['updates']):
            print("campi updates con diverso numero di elementi")
            return False
        for i in range(0,lung-1):
            updates_check = test_req['updates'][i]
            updates = req['updates'][i]
            if not check_dict(updates_check, updates):
                print("elementi campi updates non corrispondendi")
                return False
    else:
        #Nella nuova versione di mongo mongreplay mette la parte di updates dentro a documents e identifier identifica
            #il comando
        print("sono con: "+str(test_req))
        if 'identifier' in test_req and test_req['identifier'] == 'updates' and 'updates' in req:
            lung = len(test_req['documents'])
            print("sono entrato nel nuovo IF")
            if lung != len(req['updates']):
                print("campi updates con diverso numero di elementi")
                return False
            for i in range(0, lung - 1):
                updates_check = test_req['documents'][i]
                updates = req['updates'][i]
                if not check_dict(updates_check, updates):
                    print("elementi campi updates non corrispondendi")
                    return False
        else:
            #Controllo che almeno uno abbia il campo
                #Altrimenti se entrambi non lo hanno non è da considerare un errore
            if 'updates' in test_req or 'updates' in req or ( 'identifier' in test_req and test_req['identifier'] == 'updates' ):
                print("campi updates non presenti in entrambe le request")
                return False
    # Controllo campo ordered ---- bool ---to lower case
    if 'ordered' in test_req and 'ordered' in req:
        if not (str(test_req['ordered']).lower() == str(req['ordered']).lower()):
            print("campi ordered di comandi update non corrispondono")
            return False
    else:
        if 'ordered' in test_req or 'ordered' in req:
            print("campi ordered di comandi update non presenti in entrambe le richieste")
            return False
    # Controllo campo upsert ---- bool ---to lower case
    if 'upsert' in test_req and 'upsert' in req:
       if not (str(test_req['upsert']).lower() == str(req['upsert']).lower()):
           print("campi upsert di comandi update non corrispondono")
           return False
    else:
        if 'upsert' in test_req or 'upsert' in req:
            print("campi ordered di comandi update non presenti in entrambe le richieste")
            return False
    return True


#Controllo comando Insert
    #test_req contiene la richiesta di confronto
    #req contiene la richiesta da confrontare
def cmd_insert(test_req,req):
    #Controllo campo Insert
    if not check_field(test_req,req,'insert'):
        print("campi insert dei comandi insert non corrispondono")
        return False
    #Controllo campo documents ---- array di dict
    if ('documents' in test_req and 'documents' not in req) or ('documents' not in test_req and 'documents' in req):
        print("campi documents non presenti in entrambe le request")
        return False
    lung = len(test_req['documents'])
    if lung != len(req['documents']):
        print("campi documents con diverso numero di elementi")
        return False
    for i in range(0,lung-1):
        document_check = test_req['documents'][i]
        document = req['documents'][i]
        if not check_dict(document_check, document):
            print("elementi campi documents non corrispondendi")
            return False
    # Controllo campo ordered ---- bool ---to lower case
    if 'ordered' in test_req and 'ordered' in req:
        if not (str(test_req['ordered']).lower() == str(req['ordered']).lower()):
            print("campi ordered di comandi insert non corrispondono")
            return False
    else:
        if 'ordered' in test_req or 'ordered' in req:
            print("campi ordered di comandi insert non presenti in entrambe le richieste")
            return False
    return True


#Controllo comando Count
    #test_req contiene la richiesta di confronto
    #req contiene la richiesta da confrontare
def cmd_count(test_req,req):
    #Controllo campo Count
    if not check_field(test_req,req,'count'):
        print("campi count dei count non corrispondono")
        return False
    #Controllo campo query --- dict
    if ('query' in test_req and 'query' not in req) or ('query' not in test_req and 'query' in req) :
        print("campi query dei count non corrispondono")
        return False
    dict_check = test_req['query']
    dict_data = req['query']
    if not check_dict(dict_check,dict_data):
        print("elementi campi query dei count non corrispondendi")
        return False
    return True

#Controllo comando Find
    #test_req contiene la richiesta di confronto
    #req contiene la richiesta da confrontare
def cmd_find(test_req,req):
    #Controllo campo Limit
    if not check_field(test_req,req,'limit'):
        print("campi limit dei find non corrispondono")
        return False
    #Controllo campo Find
    if not check_field(test_req, req, 'find'):
        print("campi find dei find non corrispondono")
        return False
    #Controllo campo Path
    if not check_field(test_req, req, 'path'):
        print("campi path dei find non corrispondono")
        return False
    #Controllo campo Filter--->dict contenente anche id che non va confrontato--- prendo solo campi significativi
    if ('filter' in test_req and 'filter' not in req) or ('filter' not in test_req and 'filter' in req) :
        print("campi filter dei find non corrispondono")
        return False
    dict_check = test_req['filter']
    dict_data = req['filter']
    if not check_dict(dict_check,dict_data):
        print("elementi campi filter dei find non corrispondendi")
    #Se coincide tutto allora ritorno True
    return True

def text_to_bits(text, encoding='utf-8', errors='surrogatepass'):
    bits = bin(int(binascii.hexlify(text.encode(encoding, errors)), 16))[2:]
    return bits.zfill(8 * ((len(bits) + 7) // 8))

def main():
    #Attivazione del Server Mongo
    print("Attivazione Server....")
    server = MockupDB(port='27017')
    server.run()
    print("Server Mongo in esecuzione all'indirizzo "+str(server.address))

    #Aggiunta
    LOG_FILENAME = 'log_file.out'
    logging.basicConfig(filename=LOG_FILENAME, level=logging.DEBUG)
    logging.debug('File di Log per Mockup Mongo')

    print("----------------Inizializzazione------------------------------")

    getlast=0
    ismaster=0
    buildinfo=0
    saslStart=0
    saslContinue = 0
    folder = "/MockupFolder/Config"
    for conf in os.listdir(folder):
        if getlast == 0 and "getlasterror" in str(conf):
            getlast = getlast + 1
            with open(str(folder)+'/'+str(conf)) as file_data:
                data = json.load(file_data)
                #getlasterror_reply = OpReply(data["reply_data"])
                opmsgreply_getlasterror = mockupdb.make_op_msg_reply(data["reply_data"])
                server.autoresponds('getlasterror', opmsgreply_getlasterror)

        if ismaster == 0 and "ismaster" in str(conf):
            ismaster = ismaster + 1
            with open(str(folder)+'/'+str(conf)) as file_data:
                data = json.load(file_data)
                #ismaster_reply = OpReply(data["reply_data"])
                opmsgreply_ismaster = mockupdb.make_op_msg_reply(data["reply_data"]["sections"][0]["payload"])
                server.autoresponds('ismaster', opmsgreply_ismaster)

        if buildinfo == 0 and (("buildInfo" in str(conf)) or ("buildinfo" in str(conf))):
            buildinfo = buildinfo + 1
            with open(str(folder)+'/'+str(conf)) as file_data:
                data = json.load(file_data)
                #buildinfo_reply = OpReply(data["reply_data"])
                opmsgreply_buildinfo = mockupdb.make_op_msg_reply(data["reply_data"])
                server.autoresponds('buildInfo', opmsgreply_buildinfo)
                server.autoresponds('buildinfo', opmsgreply_buildinfo)

        if saslStart == 0 and "saslStart" in str(conf):
            saslStart = saslStart + 1
            with open(str(folder)+'/'+str(conf)) as file_data:
                data = json.load(file_data)
                bin_data = "cj07JVxUUDM8TXVvd08hZXE9cWondHBSZElpSmZOb21mOHluUitjMmR0Y0x3RGtYSE5pWjVXWU9SZSxzPVBzdEJqdWpXQjZEdkR6Kzk2LysxR0E9PSxpPTEwMDAw".encode("ascii")
                #data["reply_data"]["payload"] = int(text_to_bits(bin_data))
                data["reply_data"]["payload"] = base64.decodebytes(bin_data)
                saslStart_reply = OpReply(data["reply_data"])
                server.autoresponds('saslStart', saslStart_reply)

        if saslContinue == 0 and "saslContinue" in str(conf):
            saslContinue = saslContinue + 1
            with open(str(folder)+'/'+str(conf)) as file_data:
                data = json.load(file_data)
                if str(data["reply_data"]["done"]) == "false":
                    bin_data = ''.encode("ascii")
                else:
                    bin_data = "dj0zb1A2enh5anBXSW5xc25nWllzN2lYZWJ3S289".encode("ascii")
                #data["reply_data"]["payload"] = int(text_to_bits(bin_data))
                data["reply_data"]["payload"] = base64.decodebytes(bin_data)
                saslContinue_reply = OpReply(data["reply_data"])
                server.autoresponds('saslContinue', saslContinue_reply)


        if getlast == 1 and ismaster == 1 and buildinfo == 1 and saslContinue == 1 and saslStart == 1:
            break


    if(ismaster == 0):
        print("ismaster automatico")
        opmsgreply = mockupdb.make_op_msg_reply(OrderedDict([('maxWireVersion', 6), ('minWireVersion', 0), ('ok', 1.0)]))
        server.autoresponds('ismaster',opmsgreply)
    if (buildinfo == 0):
        print("buildinfo automatico")
        server.autoresponds('buildInfo')
        server.autoresponds('buildinfo')
    if (getlast == 0):
        print("getlasterror automatico")
        server.autoresponds('getlasterror')
    if (saslStart == 0):
        print("saslstart automatico")
        server.autoresponds('saslStart')
    if (saslContinue == 0):
        print("saslcontinue automatico")
        server.autoresponds('saslContinue')
    server.autoresponds('ping')


    #Nella fase di inizializzazione è possibile che vengano mandati anche dei comandi come la find, la delete e la insert
    #Non vengono mandate sempre nello stesso ordine quindi le salvo prima in una struttura dati
    #Ogni volta che mi arriva uno di questi comandi rispondo con le risposte salvate nella struttura dati
    #Ovviamente le risposte vengono lette dagli eventuali file di report salvati nell'apposita carte CMDs di MockupFolder

    find_list = []
    insert_list = []
    delete_list = []
    folder = "/MockupFolder/CMDs"
    for command in os.listdir(folder):
        if "find" in str(command):
            with open(str(folder)+'/'+str(command)) as file_data:
                data = json.load(file_data)
                data["reply_data"]["cursor"]["id"] = Int64(0)
                find_list.append(mockupdb.make_op_msg_reply(data["reply_data"]))
        if "insert" in str(command):
            with open(str(folder)+'/'+str(command)) as file_data:
                data = json.load(file_data)
                insert_list.append(mockupdb.make_op_msg_reply(data["reply_data"]))
        if "delete" in str(command):
            with open(str(folder)+'/'+str(command)) as file_data:
                data = json.load(file_data)
                delete_list.append(mockupdb.make_op_msg_reply(data["reply_data"]))

    count_find = 0
    count_insert = 0
    count_delete = 0
    while not (count_delete == len(delete_list) and count_find == len(find_list) and count_insert == len(insert_list)):
        cmd = server.receives(timeout=3000)
        if str(cmd.command_name) == "find":
            cmd.replies(find_list[count_find])
            count_find = count_find + 1
        else:
            if str(cmd.command_name) == "insert":
                cmd.replies(insert_list[count_insert])
                count_insert = count_insert + 1
            else:
                if str(cmd.command_name) == "delete":
                    cmd.replies(delete_list[count_delete])
                    count_delete = count_delete + 1
                else:
                    general_reply = mockupdb.make_op_msg_reply(OrderedDict([('n', 1), ('ok', 1.0)]))
                    cmd.replies(general_reply)

    print("----------------Inizializzazione Terminata------------------------------")

    print("in attesa di comando----MODIFICA 2.0")
    cmd = server.receives(timeout=100000)
    print("ricevuto: " + str(cmd))
    while True:
        # Adesso ricevo richieste dall'applicazione, controllo che siano corrette e invio risposte
        # while not os.path.exists('ActualFileTest.txt'):
        #     cmd.command_err(errmsg='unrecognized request')
        #     print("in attesa di comando")
        #     cmd = server.receives(timeout=100000)
        file = open('ActualFileTest.txt', 'r')
        folder_name = file.read()
        folder_name = folder_name.strip('\n')
        print(folder_name)
        folder_name2 = folder_name
        file.close()
        num_test=int(re.search(r'\d+', folder_name2).group())
        print("-----------------TEST " + str(num_test) + "----------------------")
        #os.remove("ActualFileTest.txt")
        print(folder_name)
        folder = str(folder_name)+"CMDs"
        controllo = False
        for command in sorted(os.listdir(folder), key=numericalSort):
            #Controllo che il contenuto della richiesta sia corretto
            controllo = True
            with open(str(folder)+'/'+str(command)) as file_data:
                print("-------------------"+str(command))
                data = json.load(file_data)
                print("stampo campo command name: " + str(cmd.command_name))
                #Nel file di report (nel caso di op_msg della versione aggiornata di mogno) è presente il campo sections
                    #che può avere più elementi al suo interno contenenti i vari campi da testare
                len_str = len(data["request_data"]["sections"])
                if 'sections' in data["request_data"]:
                    string_report = ''
                    for i in range(0,len_str):
                        payload = str(data["request_data"]["sections"][i]["payload"])
                        #Se non è il primo json allora devo togliere la parentesi di inizio per la stringa
                         #con un solo json
                        if i > 0:
                            payload = payload[1:]
                        #Se non è l'ultimo json devo sostituire l'ultima parentesi con una virgola per separarlo dal successivo
                        if  i < (len_str-1):
                            payload = payload[:-1]+","
                        string_report = string_report + payload
                    string_report = string_report.replace("'", '"')
                    string_report = string_report.replace("True", "true")
                    string_report = string_report.replace("False", "false")
                    data_report = json.loads(string_report)
                else:
                    data_report = data["request_data"]

                len_str = len(data["reply_data"]["sections"])
                if 'sections' in data["reply_data"]:
                    string_reply = ''
                    for i in range(0, len_str):
                        payload =  str(data["reply_data"]["sections"][i]["payload"])
                        # Se non è il primo json allora devo togliere la parentesi di inizio per la stringa
                        # con un solo json
                        if i > 0:
                            payload = payload[1:]
                        # Se non è l'ultimo json devo sostituire l'ultima parentesi con una virgola per separarlo dal successivo
                        if i < (len_str - 1):
                            payload = payload[:-1] + ","
                        string_reply = string_reply + payload
                    string_reply = string_reply.replace("True", "true")
                    string_reply = string_reply.replace("False", "false")
                    string_reply = string_reply.replace("'", '"')
                    data_reply = json.loads(string_reply)
                else:
                    data_reply = data["reply_data"]

                #------------da qua confronto richiesta-------------
                request = json.loads(str(cmd))
                print("Controllo correttezza richiesta...")
                print("da file ho letto:" + str(data_report))
                print("da comando ricevuto:" + str(request))
                dispatcher = {'update': cmd_update, 'insert':cmd_insert, 'delete':cmd_delete, 'find':cmd_find, 'count': cmd_count}
                ris = dispatcher[cmd.command_name](data_report,request)
                print(ris)

                # Aggiunta
                try:
                    logging.debug("-----------------TEST " + str(num_test) + "----------------------")
                    assert ris == True
                    logging.debug('Success!')
                    print("Success!")
                    print("considero ------> " + str(data_reply))
                    # Se il confronto è andato a buon fine preparo la risposta
                    if cmd.command_name == "find" and 'cursor' in data_reply and 'id' in data_reply["cursor"] \
                            and '$numberLong' in data_reply["cursor"]["id"]:
                        number_long = data_reply["cursor"]["id"]["$numberLong"]
                        data_reply["cursor"]["id"] = Int64(number_long)
                    if 'cursor' in data_reply and 'firstBatch' in data_reply["cursor"]:
                        len_firstbastch = len(data_reply["cursor"]["firstBatch"])
                        for i in range(0, len_firstbastch):
                            if 'lastSeen' in data_reply["cursor"]["firstBatch"][i] and "$date" in \
                                    data_reply["cursor"]["firstBatch"][i]["lastSeen"]:
                                data = json.loads(
                                    str(data_reply["cursor"]["firstBatch"][i]["lastSeen"]).replace("'", '"'))
                                d = dateutil.parser.parse(data["$date"])
                                data_reply["cursor"]["firstBatch"][i]["lastSeen"] = d
                            if '_id' in data_reply["cursor"]["firstBatch"][i] and "date" in \
                                    data_reply["cursor"]["firstBatch"][i]["_id"] and "$date" in \
                                    data_reply["cursor"]["firstBatch"][i]["_id"]["date"]:
                                data = json.loads(
                                    str(data_reply["cursor"]["firstBatch"][i]["_id"]["date"]).replace("'", '"'))
                                d = dateutil.parser.parse(data["$date"])
                                data_reply["cursor"]["firstBatch"][i]["_id"]["date"] = d
                            if 'scheduledNotifications' in data_reply["cursor"]["firstBatch"][i] \
                                    and 'REMIND' in data_reply["cursor"]["firstBatch"][i]["scheduledNotifications"] \
                                    and 'lastNotified' in \
                                    data_reply["cursor"]["firstBatch"][i]["scheduledNotifications"]["REMIND"] \
                                    and "$date" in \
                                    data_reply["cursor"]["firstBatch"][i]["scheduledNotifications"]["REMIND"][
                                        "lastNotified"]:
                                print("entro per modificare la data")
                                data = json.loads(str(
                                    data_reply["cursor"]["firstBatch"][i]["scheduledNotifications"]["REMIND"][
                                        "lastNotified"]).replace("'", '"'))
                                d = dateutil.parser.parse(data["$date"])
                                data_reply["cursor"]["firstBatch"][i]["scheduledNotifications"]["REMIND"][
                                    "lastNotified"] = d
                    # Se corretto mando la risposta contentuta nel file di report
                    response = mockupdb.make_op_msg_reply(data_reply)
                    cmd.replies(response)
                except AssertionError:
                    logging.exception(str(traceback.print_exc()))
                    logging.debug("da file ho letto:" + str(data_report))
                    logging.debug("da comando ho ricevuto:" + str(request))
                    cmd.command_err(errmsg='unrecognized request')
                # Fine Aggiunta
            print("in attesa di comando")
            cmd = server.receives(timeout=100000)
            print("ricevuto: " + str(cmd))
        if not controllo:
            logging.debug("ERROR: Nessuna risposta al comando")
            cmd.command_err(errmsg='unrecognized request')
            print("in attesa di comando")
            cmd = server.receives(timeout=100000)
            print("ricevuto: " + str(cmd))




if __name__ == "__main__":
    main()
