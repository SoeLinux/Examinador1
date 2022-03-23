#!/bin/bash
# A Menu driver Configuration test system
INTERACTIVE=True
BACKTITLE="U.A.G.R.M SCHOOL OF ENGINEERING, DIPLOMADO EN INFRAESTRUCTURA TI EN LA NUBE, SEGURIDAD Y HARDENING EN GNU/LINUX"
DATAFILE="./dominios.txt"
DATA=()
NOTA=()
SPIP=()
ROOT_CA=''
DIRECTORIO_RESULTADO="/tmp/Examen1"
PUBKEY="./public.pem"
FILE_TO_VERIFY="./examina.sh"
SIGNATURE_FILE="./firma.dat"
NOTA_TOTAL=0
#DEBUG
# set -x
#export NEWT_COLORS='
#window=,red
#border=white,red
#textbox=white,red
#button=black,white
#'
#User that use sudo  
USER=${SUDO_USER:-$(who | awk '{ print $1 }')}
IP=$(ip -4 route get 8.8.8.8| awk {'print $7'}|tr -d '\n')

if [ $(id -u) -ne 0 ]; then
  printf "Este Script debe ser ejecutado como root. Intente  'sudo ./examina.sh'\n"
  exit 1
fi

calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=24
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

my_add() {
    n="$@"; bc <<< "${n// /+}"; 
}

ipsplit() { 
    local IFS=.; SPIP=(.$*); 
    echo ${SPIP[1]}
}

do_suma() {
    if [ ${#NOTA[@]} -lt 1 ]; then
        whiptail --msgbox "Por favor ejecute las opciones desde la 4 hasta la 28 para ver los Resultados." 20 60 2
    else
        n="${NOTA[@]}" 
        NOTA_TOTAL=$(bc <<< "${n// /+}")
        NOTA_FINAL="$(echo "scale=10;45/26*$NOTA_TOTAL" | bc)"
        NOTA_FINAL="$(printf %.$2f $NOTA_FINAL)"
        whiptail --msgbox " Estimado Alumno ${DATA[2]}\n\n Tu Nota Total es: $NOTA_TOTAL\n\n Y tu NOTA FINAL es $NOTA_FINAL sobre 45 Puntos." 20 60 2
    fi    
}

do_resultado(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  if [ -z "$ROOT_CA" ]; then
      whiptail --msgbox "Por favor corra el ejercicio 1 de NGINX\n" 20 60 2
      return
  fi    
  
    openssl base64 -d -in $SIGNATURE_FILE -out /tmp/sign.sha256
    VERIFI="$(openssl dgst -sha256 -verify $PUBKEY -signature /tmp/sign.sha256 $FILE_TO_VERIFY)"
    rm -f /tmp/sign.sha256
    IS_OK="$(echo $VERIFI |grep 'OK')"
  if [ -n "$IS_OK" ]; then
      mkdir -p $DIRECTORIO_RESULTADO
      cp -a /etc $DIRECTORIO_RESULTADO/
      cp -a $ROOT_CA $DIRECTORIO_RESULTADO/
      do_suma;
      MY_NOTA="${DATA[2]} , $NOTA_FINAL"
      whiptail --yesno "Estimado ${DATA[2]}, esta seguro de crear el archivo de resultado\nSu nota es $NOTA_FINAL?" $DEFAULT 20 60 2
      RET=$?
      if [ $RET -eq 0 ]; then
          ENCRYPT="$(echo $MY_NOTA|openssl  pkeyutl -encrypt -pubin -inkey $PUBKEY -out $DIRECTORIO_RESULTADO/xyz.dat )"    
          tar czf /tmp/examen1.tar.gz $DIRECTORIO_RESULTADO 2>/dev/null
          RET1=$?
          rm -rf $DIRECTORIO_RESULTADO
          if [ $RET1 -eq 0 ]; then 
              whiptail --msgbox "El archivo /tmp/examen.tar.gz esta listo para ser enviado \n" 20 60 2
          else
              whiptail --msgbox "Ocurrió  un error al generar el  archivo de resultados \n" 20 60 2
          fi    
      fi    
  else
      whiptail --msgbox "Ocurrió  un error se encontró un cambio en el script por favor vuela a copiarlo  \n" 20 60 2
  fi 

}


do_todos() {
    do_DNS_1;
    do_DNS_2;
    do_DNS_3;
    do_DNS_4;
    do_DNS_5;
    do_DNS_6;
    do_DNS_7;
    do_DNS_8;
    do_DNS_9;
    do_DNS_10;
    do_DNS_11;
    do_DNS_12;
    do_DNS_13;
    do_DNS_14;
    do_NGINX_1;
    do_NGINX_2;  
    do_NGINX_3;  
    do_NGINX_4;  
    do_NGINX_5;  
    do_NGINX_6;  
    do_NGINX_7;  
    do_NGINX_8;  
    do_NGINX_9;  
    do_NGINX_10;  
    do_NGINX_11;  
    do_NGINX_12;  
    do_suma;

}

# DNS 1)
# Se debe configurar el nombre del servidor de acuerdo a la asignación antes 
# defendida: en este caso el nombre del servidor debe ser sever01.jhondoe.com,
# la configuracoin debe ser FQND (fully qualified domain name), y debe ser 
# reflejada en el archivo de /etc/host con el ip del servidor

do_DNS_1() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  CURRENT_HOSTNAME=`hostname --fqdn`  
  DESIRED_HOSTNAME=${DATA[4]}
  DESIRED_HOSTNAME="$(echo -e "${DESIRED_HOSTNAME}" | tr -d '[:space:]')"
  NOTA_INTERNA1=0  
  NOTA_INTERNA2=0
  DNS_1_LOG=''
  
  if [ "$CURRENT_HOSTNAME" == "$DESIRED_HOSTNAME" ]; then
       DNS_1_LOG="El nombre de dominio es correcto en él sistema"
       NOTA_INTERNA1=0.5
   else
       NOTA_INTERNA1=0 
       DNS_1_LOG="El nombre de dominio en él sistema no esta correcto debería ser: $DESIRED_HOSTNAME"
  fi    
  HOSTS=$(cat /etc/hosts |grep $IP )
  CURRENT_IP=$(echo $HOSTS | cut -d ' ' -f 1 )
  CURRENT_HOSTNAME_H=$(echo $HOSTS | cut -d ' ' -f 2 )
      
  if [ "$CURRENT_IP" == $IP ] && [ "$CURRENT_HOSTNAME_H" == $DESIRED_HOSTNAME ]; then
      DNS_1_LOG="$DNS_1_LOG\n \nEl nombre de dominio e IP en el archivo /etc/hosts es Correcto"
      NOTA_INTERNA2=0.5
  else
      NOTA_INTERNA2=0
      DNS_1_LOG="$DNS_1_LOG\n \nEl nombre de dominio e IP en el archivo /etc/hosts no esta configurado"
  fi
  NOTA[1]=$(echo $NOTA_INTERNA1 + $NOTA_INTERNA2 | bc)
  whiptail --msgbox "$DNS_1_LOG \n\nNota parcial ${NOTA[1]}." 20 60 2
}

# DNS 2)
# Luego se configura el servido DNS (bind) como master primario del domino 
# jhondoe.com, NO se configurara un servidor secundario. El servidor DNS debe 
# tener un acl de tal modo que solo sea recursivo para si mismo.

do_DNS_2(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  n21=0
  n22=0
  n23=0
  DNS_2_LOG=''
  #Probando si esta configurado el dominio
  HAY_FILES="$(find /etc/bind -type f |grep $DESIRED_DOMAIN|grep 'db'|grep -v 'signed')" 
  HAY_ZONA="$(grep "^zone" /etc/bind/named.conf.local| grep $DESIRED_DOMAIN |cut -d ' ' -f 2)"
  HAY_RECURSION="$(cat /etc/bind/named.conf.options |grep -v "#" |grep allow-r|awk '{print $1}')" 

  if [ -n "$HAY_FILES" ]; then 
      n21=0.25
      DNS_2_LOG=" Archivo de zona encontrado : $HAY_FILES\n"
  else
      n21=0
      DNS_2_LOG=" No encuentro el archivo de zona db.$DESIRED_DOMAIN \n"
  fi
  if [ -n "$HAY_ZONA" ]; then
      n22=0.5
      DNS_2_LOG="$DNS_2_LOG\n Zona declara en la configuración: $HAY_ZONA\n"
  else    
      n22=0
      DNS_2_LOG="$DNS_2_LOG\n Zona no encontrada en la configuración: \n"
  fi
  if [ -n "$HAY_RECURSION" ]; then
      n23=0.25
      DNS_2_LOG="$DNS_2_LOG\n Recursión declarada en la configuración\n $HAY_RECURSION"
  else    
      n23=0
      DNS_2_LOG="$DNS_2_LOG\n No se encontró recursión  en la configuración\n"
  fi    
  NOTA[2]=$(echo $n21 + $n22 + $n23 | bc)
  whiptail --msgbox "$DNS_2_LOG \n\n Nota parcial ${NOTA[2]}." 20 60 2
}

# DNS 3)
# Debe existir un registro A de server01.jhondoe.com apuntando al ip del servidor

do_DNS_3(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  DESIRED_HOSTNAME=${DATA[4]}
  DESIRED_HOSTNAME="$(echo -e "${DESIRED_HOSTNAME}" | tr -d '[:space:]')"
  HAY_FILES="$(find /etc/bind -type f |grep $DESIRED_DOMAIN|grep 'db'|grep -v 'signed')" 
  n31=0
  n32=0
  DNS_3_LOG=''

  if [ -z "$HAY_FILES" ]; then
     DNS_3_LOG=" Archivo de zona no encontrada en la configuración\n "
     NOTA[3]=0
     whiptail --msgbox "$DNS_3_LOG \n\nNota parcial ${NOTA[3]}." 20 60 2
     return
  fi     
  HAY_REG_A="$(cat $HAY_FILES | grep 'A '| grep $DESIRED_HOSTNAME)"
  if [ -n "$HAY_REG_A" ]; then
    DNS_3_LOG=" Se ha encontrado el registro A de $DESIRED_HOSTNAME\n"  
    n31=0.5    
  else  
    n31=0    
    DNS_3_LOG=" No se a encontrado el registro A server01.$DESIRED_DOMAIN\n"  
  fi    
  HAY_IP="$(echo $HAY_REG_A|grep $IP)"

  if [ -n "$HAY_IP" ]; then
      n32=0.5
      DNS_3_LOG="$DNS_3_LOG\n El registro A apunta al IP $IP"
  else
      n32=0
      DNS_3_LOG="$DNS_3_LOG\n El registro A NO apunta al IP $IP"
  fi
  NOTA[3]=$(echo $n31 + $n32 | bc)
  whiptail --msgbox "$DNS_3_LOG \n\nNota parcial ${NOTA[3]}." 20 60 2
}

# DNS 4)
# Debe existir un registro MX de prioridad 10 apuntando a server01.jhondoe.com
do_DNS_4(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  DESIRED_HOSTNAME=${DATA[4]}
  DESIRED_HOSTNAME="$(echo -e "${DESIRED_HOSTNAME}" | tr -d '[:space:]')"
  HAY_FILES="$(find /etc/bind -type f |grep $DESIRED_DOMAIN|grep 'db'|grep -v 'signed')" 
  n41=0
  n42=0
  DNS_3_LOG=''

  if [ -z "$HAY_FILES" ]; then
     DNS_4_LOG=" Archivo de zona no encontrada en la configuración\n "
     NOTA[4]=0
     whiptail --msgbox "$DNS_4_LOG \n\nNota parcial ${NOTA[4]}." 20 60 2
     return
  fi     
  HAY_REG_MX="$(cat $HAY_FILES | grep 'MX '| grep $DESIRED_HOSTNAME)" 
  if [ -n "$HAY_REG_MX" ]; then
    DNS_4_LOG=" Se ha encontrado el registro MX de $DESIRED_DOMAIN\n"  
    n41=1    
  else  
    n41=0    
    DNS_4_LOG=" No se a encontrado el registro MX para $DESIRED_DOMAIN\n"  
  fi    
  NOTA[4]=$(echo $n41 + $n42 | bc) 
  whiptail --msgbox "$DNS_4_LOG \n\nNota parcial ${NOTA[4]}." 20 60 2
}

# DNS 5)
# Debe existir un registro CNAME de www.jhondoe.com apuntando a server01.jhondoe.com
do_DNS_5(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  DESIRED_HOSTNAME=${DATA[4]}
  DESIRED_HOSTNAME="$(echo -e "${DESIRED_HOSTNAME}" | tr -d '[:space:]')"
  HAY_FILES="$(find /etc/bind -type f |grep $DESIRED_DOMAIN|grep 'db'|grep -v 'signed')" 
  n51=0
  n52=0
  DNS_5_LOG=''

  if [ -z "$HAY_FILES" ]; then
     DNS_4_LOG=" Archivo de zona no encontrada en la configuración\n "
     NOTA[5]=0
     whiptail --msgbox "$DNS_4_LOG \n\nNota parcial ${NOTA[5]}." 20 60 2
     return
  fi     
  HAY_REG_WWW="$(cat $HAY_FILES | grep -i 'www'| grep $DESIRED_HOSTNAME|grep 'CNAME')" 

  if [ -n "$HAY_REG_WWW" ]; then
    DNS_5_LOG=" Se ha encontrado el registro CNAME www de $DESIRED_DOMAIN\n"  
    n51=1    
  else  
    n41=0    
    DNS_5_LOG=" No se a encontrado el registro CNAMe www para $DESIRED_DOMAIN\n"  
  fi    
  NOTA[5]=$(echo $n51 + $n52 | bc) 
  whiptail --msgbox "$DNS_5_LOG \n\nNota parcial ${NOTA[5]}." 20 60 2
}

# DNS 6)
# Se debe configurar la Zona reversa (PTR) acorde a la red y el ip del servidor
do_DNS_6(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  ipsplit $IP
  DNS_6_LOG=""
  n61=0
  n62=0
  HAY_PTR="$(grep "^zone" /etc/bind/named.conf.local| grep 'addr.arpa'|cut -d ' ' -f 2)"
  HAY_FILES="$(find /etc/bind -type f |grep "${SPIP[0]}.${SPIP[1]}" |grep 'db'|grep -v 'signed')" 

  if [ -n "$HAY_FILES" ]; then 
      n61=0.5
      DNS_6_LOG=" Archivo de zona PTR encontrado : $HAY_FILES\n"
  else
      n61=0
      DNS_6_LOG=" No encuentro el archivo de zona db"${SPIP[0]}.${SPIP[1]}" \n"
  fi
  if [ -n "$HAY_PTR" ]; then
      n62=0.5
      DNS_6_LOG="$DNS_6_LOG\n Zona declara en la configuración: $HAY_PTR\n"
  else    
      n62=0
      DNS_6_LOG="$DNS_6_LOG\n Zona PTR no encontrada en la configuración: \n"
  fi
  NOTA[6]=$(echo $n61 + $n62 | bc)
  whiptail --msgbox "$DNS_6_LOG \n\nNota parcial ${NOTA[6]}." 20 60 2
}

# DNS 7)
# Se debe verificar toda la configuración y reiniciar el servicio, el DNS debe ser funcional
do_DNS_7(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  DNS_7_LOG=''
  n71=0
  n72=0
  n73=0
  IS_RUNNING="$(systemctl status named|grep 'active (running)')"

  if [ -n "$IS_RUNNING" ]; then 
      n71=0.25
      DNS_7_LOG=" El servicio esta NAMED está corriendo \n $IS_RUNNING \n"

      # Revisamos si hay dominio (NS)
      HAY_NS="$(dig  +short @$IP NS $DESIRED_DOMAIN )"

      if [ -n "$HAY_NS"  ]; then
         n72=0.25
         DNS_7_LOG="$DNS_7_LOG\n El servidor named responde a la pregunta NS:\n $HAY_NS"
         HAY_NS="$(echo $HAY_NS | head -1)" 
         HAY_NS_IP="$(dig  +short @$IP A $HAY_NS)"
         if [ -n "$HAY_NS_IP" ]; then 
            if [ "$IP" == "$HAY_NS_IP" ]; then 
                n73=0.5
                DNS_7_LOG="$DNS_7_LOG\n El servidor named responde al ip de NS\n $HAY_NS_IP"
            else
               n73=0 
               DNS_7_LOG="$DNS_7_LOG\n El servidor named responde al ip de NS pero no es la IP del servidor named\n $HAY_NS_IP "
            fi    
                
         else
            n73=0
            DNS_7_LOG="$DNS_7_LOG\n El servidor named no sabe que IP es el NS "
         fi   
      else  
         n72=0 
         n73=0
         DNS_7_LOG="$DNS_7_LOG\n El servidor named no responde a la pregunta NS:"
      fi   
  else
      n71=0
      n72=0
      n73=0
      DNS_7_LOG="El servicio NAMED no esta corriendo \n "
 fi

  NOTA[7]=$(echo $n71 + $n72 + $n73 | bc)
  whiptail --msgbox "$DNS_7_LOG \n\nNota parcial ${NOTA[7]}." 20 60 2
}

# DNS 8
# Una vez que el dominio este configurado se debe genera dos pares de llaves 
# (ZSK, KSK) para el domino jhondoe.com
do_DNS_8(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_8_LOG=''
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_KEY_FILES="$(find /etc/bind/zones -type f | grep "K$DESIRED_DOMAIN" |grep 'key'  )" 
  n81=0
  n82=0
  if [ -n "$HAY_KEY_FILES" ]; then 
     HAY_KEY_FILES="$(echo $HAY_KEY_FILES | tr '\n' ' ')"
     HAY_KEY_FILES_1="$(echo $HAY_KEY_FILES | cut -d ' ' -f 1)"
     HAY_KEY_FILES_2="$(echo $HAY_KEY_FILES | cut -d ' ' -f 2)"
     if [ -n "$HAY_KEY_FILES"  ]; then
         HAY_KSK="$( echo "$HAY_KEY_FILES"|xargs cat |grep 'key-signing key' )" 
         if [ -n "$HAY_KSK"  ]; then
            n81=0.5
            DNS_8_LOG=" EL archivo de llaves KSK existe\n $HAY_KSK"
         else   
            n81=0    
            DNS_8_LOG=" El archivo de llaves KSK no existe\n"
         fi
         HAY_ZSK="$(echo $HAY_KEY_FILES|xargs cat|grep 'zone-signing key' )" 

         if [ -n "$HAY_ZSK" ]; then
             n82=0.5
             DNS_8_LOG="$DNS_8_LOG\n El archivo de llaves ZSK existe \n $HAY_ZSK"
         else
             n82=0
             DNS_8_LOG="$DNS_8_LOG\n El archivo de llaves ZSK no existe\n"
         fi    
     else
       n81=0
       n82=0
       DNS_8_LOG="No se encontraron los archivos de llaves"
     fi    
  else   
      n81=0
      n82=0
      DNS_8_LOG="No se encontraron los archivos de llaves"
  fi
  NOTA[8]=$(echo $n81 + $n82 | bc)
  whiptail --msgbox "$DNS_8_LOG \n\nNota parcial ${NOTA[8]}." 20 60 2
}

# DNS 9)
# Se debe configurar los registros DNSKEY del dominio (o en la zona) jhondoe.com
do_DNS_9(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_9_LOG=''
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_KEY_FILES="$(find /etc/bind/zones -type f | grep "K$DESIRED_DOMAIN" |grep 'key'  )" 
  HAY_FILES="$(find /etc/bind -type f |grep $DESIRED_DOMAIN|grep 'db'|grep -v 'signed')" 
  n91=0
  n92=0
  if [ -n "$HAY_FILES" ]; then
    HAY_KEY_FILES="$(echo $HAY_KEY_FILES | tr '\n' ' ')"                       
    HAY_KEY_FILES_1="$(echo $HAY_KEY_FILES | cut -d ' ' -f 1)"                 
    HAY_KEY_FILES_1="$(basename $HAY_KEY_FILES_1)"
    HAY_KEY_FILES_2="$(echo $HAY_KEY_FILES | cut -d ' ' -f 2)"  
    HAY_KEY_FILES_2="$(basename $HAY_KEY_FILES_2)"
    HAY_ZONA_I_1="$(cat $HAY_FILES| grep "$HAY_KEY_FILES_1")"
    HAY_ZONA_I_2="$(cat $HAY_FILES| grep "$HAY_KEY_FILES_2")"

    if [ -n "$HAY_ZONA_I_1" ]; then 
        n91=0.5
        DNS_9_LOG="El archivo de llave $HAY_KEY_FILES_1 esta declara en el archivo de Zona\n $HAY_FILES"
    else
        n91=0
        DNS_9_LOG="El archivo de llave $HAY_KEY_FILES_1 no esta declara en el archivo de Zona\n $HAY_FILES"
    fi
    if [ -n "$HAY_ZONA_I_2" ]; then
        n92=0.5
        DNS_9_LOG="$DNS_9_LOG\n El archivo de llave $HAY_KEY_FILES_2 esta declara en el archivo de Zona\n $HAY_FILES"
    else
        n92=0
        DNS_9_LOG="$DNS_9_LOG\n El archivo de llave $HAY_KEY_FILES_2 no esta declara en el archivo de Zona\n $HAY_FILES"
    fi    
  else  
      n91=0
      n92=0
      DNS_9_LOG="No se encontró la configuración de zona para el Dominio $DESIRED_DOMAIN"
  fi    
  NOTA[9]=$(echo $n91 + $n92 | bc)
  whiptail --msgbox "$DNS_9_LOG \n\nNota parcial ${NOTA[9]}." 20 60 2
}

# DNS 10)
# Se debe firmar toda la zona/dominio jhondoe.com generando el archivo de configuración del dominio jhondoe.com
do_DNS_10(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_10_LOG=''
  DESIRED_DOMAIN=${DATA[3]}  
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_FILES="$(find /etc/bind -type f |grep $DESIRED_DOMAIN|grep 'db'|grep  'signed')" 
  n100=0
  n101=0
  if [ -n "$HAY_FILES" ]; then
      HAY_KEY_IN_FILE="$(cat $HAY_FILES |grep 'RRSIG'|grep 'A ')"  
      n100=0.5
      if [ -n "$HAY_KEY_IN_FILE" ]; then
          n101=0.5
          DNS_10_LOG="EL archivo firmado es: \n $HAY_FILES \n Y tien los registros firmados"
      else
          n101=0
          DNS_10_LOG="El archivo firmado es\n $HAY_FILES \n Pero no se enuentras registros firmados"
      fi    
  else
    n100=0
    DNS_10_LOG="No se encontró el archivo firmado"
  fi  
  NOTA[10]=$(echo $n100 + $n101 | bc)
  whiptail --msgbox "$DNS_10_LOG \n\nNota parcial ${NOTA[10]}." 20 60 2
}

# DNS 11)
# Se debe apuntar al nuevo archivo de zona/domino con la extinción .signed
do_DNS_11(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_11_LOG=''
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_ZONA="$(grep "^zone" /etc/bind/named.conf.local| grep $DESIRED_DOMAIN |cut -d ' ' -f 2)"
  HAY_FILE_0="$(cat /etc/bind/named.conf.local|grep file|grep signed|grep $DESIRED_DOMAIN)"  
  n110=0
  n111=0
  if [ -n "$HAY_ZONA" ]; then
     if [ -n "$HAY_FILE_0" ]; then
        n111=1
        DNS_11_LOG="Se encontró la zona apuntando al archivo firmado\n"
     else   
        n111=0 
        DNS_11_LOG="No se encontró la zona apuntando al archivo firmado\n"
     fi    
  else
     DNS_11_LOG="No se encontró la zona para el domino $DESIRED_DOMAIN "
  fi
  NOTA[11]=$(echo $n111 + $n110  | bc)
  whiptail --msgbox "$DNS_11_LOG \n\nNota parcial ${NOTA[11]}." 20 60 2
}

#DNS 12)
# Se debe comprobar que la configuración este correcta y reiniciar el servicio
do_DNS_12(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_12_LOG=''
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_SERVICIO="$(delv @"$IP" $DESIRED_DOMAIN ANY 2>/dev/null| grep $DESIRED_DOMAIN|grep 'DNSKEY' | grep '257')"
  n121=0
  n122=0
  if [ -n "$HAY_SERVICIO" ]; then
      n121=1
      DNS_12_LOG="El servicio esta funcionando con la configuración DNSSEC\n\n $HAY_SERVICIO"
  else
      n121=0
      DNS_12_LOG="El servicio no esta funcionando con la configuración DNSSEC"
  fi    
  NOTA[12]=$(echo $n121 + $n122  | bc)
  whiptail --msgbox "$DNS_12_LOG \n\nNota parcial ${NOTA[12]}." 20 60 2
}

#DNS 13)
# El servidor DNS debe ser funcional al final del ejercicio
do_DNS_13(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_13_LOG=''
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_RESOLVER="$(dig @"$IP" www.google.com +short 2>/dev/null|wc -l)"
  n131=0
  n132=0
  if [ "$HAY_RESOLVER" -gt '0' ];then
      n131=1
      DNS_13_LOG="El servidor DNS es funcional "
  else
      n131=0
      DNS_13_LOG="El servidor DNS no es funcional\n No puede resolver www.google.com "
  fi
  NOTA[13]=$(echo $n131 + $n132  | bc)
  whiptail --msgbox "$DNS_13_LOG \n\nNota parcial ${NOTA[13]}." 20 60 2
}

# DNS 14)
# Por último se debe configurar el servidor ubuntu/linux para que su resolver 
# DNS sea el local que acabamos de configurar
do_DNS_14(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  DNS_14_LOG=''
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  HAY_STATUS="$(resolvectl status |grep 'Current DNS'|cut -d ' ' -f 6)"
  n141=0
  n142=0
  if [ "$HAY_STATUS" == "$IP" ]; then
      n141=1
      DNS_14_LOG="El sistema tiene como DNS a, el bind configurado\n"
  else 
      n141=0
      DNS_14_LOG="El sistema no tiene como DNS a, el bind configurado\n"
  fi    
  NOTA[14]=$(echo $n141 + $n142  | bc) 
  whiptail --msgbox "$DNS_14_LOG \n\nNota parcial ${NOTA[14]}." 20 60 2
}

# NGINX 1)
# Se debe crear con ayuda de openssl una Autoridad de Certificación (local),
# para este efecto, se creara en el home del usuario (alumno) el directorio 
# myCA y su correspondiente estructura:
#  serial
#  index.txt
#  private (directorio)
#  signedcerts (directorio)

do_NGINX_1() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  NGINX_1_LOG=''
  nx11=0
  nx12=0
  nx13=0
  nx14=0
  nx15=0
  # El separador es un enter
  IFS=$'
'
  HAY_DIRETORY=( "$(find /home /root -type d |grep myCA)" )
  A_DIRECTORIES=( $HAY_DIRETORY )
  MY_CA=''
  PRIVATE=''
  SIGNEDCERTS=''
  if [ -n "$HAY_DIRETORY" ]; then
      L=${#A_DIRECTORIES[@]}
      if [ $L -gt 0 ]; then
          
          for d in "${A_DIRECTORIES[@]}"
          do
              MY_CA_L="$( basename $d |grep 'myCA') "
              MY_CA_L="$(echo -e "$MY_CA_L" | tr -d '[:space:]')"
              PRIVATE_L="$( basename $d |grep 'private')"
              SIGNEDCERTS_L="$( basename $d |grep 'signedcerts')"
              if [ -n "$MY_CA_L"  ]; then
                  MY_CA=$MY_CA_L
                  ROOT_CA=$d
                  nx11=0.2
                  NGINX_1_LOG=" El directorio raíz es $ROOT_CA\n\n"
              fi    
              if [ -n "$PRIVATE_L" ]; then 
                  PRIVATE=$PRIVATE_L
                  nx12=0.2
                  NGINX_1_LOG="$NGINX_1_LOG\n Existe el directorio private\n "
              fi
              if [ -n "$SIGNEDCERTS_L" ]; then
                  SIGNEDCERTS=$SIGNEDCERTS_L
                  nx13=0.2
                  NGINX_1_LOG="$NGINX_1_LOG\n Existe el directorio signedcerts\n "
              fi    
          done    
      fi    
      if [ -n "$ROOT_CA" ]; then
          HAY_SERIAL="$(ls -1 "$ROOT_CA/serial")"  
          if [ -n "$HAY_SERIAL" ]; then
              nx14=0.2
              NGINX_1_LOG="$NGINX_1_LOG\n Existe el archivo serial\n"
          else 
              nx14=0.2
          fi
          HAY_INDEX="$(ls -1 "$ROOT_CA/index.txt")"
          if [ -n "$HAY_INDEX" ]; then
              nx15=0.2
              NGINX_1_LOG="$NGINX_1_LOG\n Existe el archivo index.txt\n"
          else    
              nx15=0
          fi    
      else 
          nx11=0
      fi    
  else
      nx11=0
      nx12=0
      NGINX_1_LOG="No se encontró el directorio myCA"
  fi    
  NOTA[15]=$(echo $nx11 + $nx12 + $nx13 + $nx14 + $nx15  | bc) 
  whiptail --msgbox "$NGINX_1_LOG \n\nNota parcial ${NOTA[15]}." 20 60 2

}  

# NGINX 2)
# Se debe crear un archivo de configuración de openssl (caconfig.cnf), con 
# el siguiente detalle
# commonName = UAGRM Root Certificate Authority
# stateOrProvinceName = Santa Cruz
# countryName = BO
# emailAddress = postgradocomputacion@uagrm.edu.bo
# organizationName = Universidad Autonoma Gabriel Rene Moreno
# organizationalUnitName = SCHOOL OF ENGINEERING


do_NGINX_2() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  if [ -z "$ROOT_CA" ]; then
      whiptail --msgbox "Por favor corra el ejercicio 1 de NGINX\n" 20 60 2
      return
  fi    

  NGINX_2_LOG=''
  nx21=0
  nx22=0
  nx23=0
  nx24=0
  nx25=0
  MY_CACONF="$ROOT_CA/caconfig.cnf"
  MY_CACONF_EX="$(ls -1 $MY_CACONF)" 
  if [ -n "$MY_CACONF_EX" ]; then
     nx21=0.2
     HAY_COMMON_NAME="$(cat $MY_CACONF | grep -i 'UAGRM Root Certificate Authority')"
     HAY_STATE="$(cat $MY_CACONF | grep -e 'Santa Cruz')"
     HAY_CONTRY="$(cat $MY_CACONF | grep -e 'BO')"
     HAY_UNIT="$(cat $MY_CACONF | grep -e 'SCHOOL OF ENGINEERING')"
     if [ -n "$HAY_COMMON_NAME" ]; then
         nx22=0.2
         NGINX_2_LOG="El commonName es $HAY_COMMON_NAME\n"
     else     
         nx22=0 
         NGINX_2_LOG="El commonName incorrecto\n"
     fi    
     if [ -n "#HAY_STATE" ]; then
         nx23=0.2 
         NGINX_2_LOG="$NGINX_2_LOG\nEl stateOrProvinceName es $HAY_STATE\n"
     else 
         nx23=0
         NGINX_2_LOG="$NGINX_2_LOG\nEl stateOrProvinceName es incorrecto\n"
     fi    
     if [ -n "$HAY_CONTRY" ]; then 
         nx24=0.2
         NGINX_2_LOG="$NGINX_2_LOG\nEl countryName es $HAY_CONTRY\n"
     else 
         nx24=0
         NGINX_2_LOG="$NGINX_2_LOG\nEl countryName es incorrecto\n"
     fi    
     if [ -n "$HAY_UNIT" ]; then
         nx25=0.2
         NGINX_2_LOG="$NGINX_2_LOG\nEl organizationalUnitName es $HAY_UNIT\n"
     else 
         nx25=0
         NGINX_2_LOG="$NGINX_2_LOG\nEl organizationalUnitName es incorrecto"
     fi    
  else 
      nx21=0
      nx22=0
      nx23=0
      nx24=0
      nx25=0
      NGINX_2_LOG="No se encontró el archivo de configuración $MY_CACONF\n"
  fi 

  NOTA[16]=$(echo $nx21 + $nx22 + $nx23 + $nx24 + $nx25  | bc) 
  whiptail --msgbox "$NGINX_2_LOG \n\nNota parcial ${NOTA[16]}." 20 76 2

}
# NGINX 3)
# Se debe generar la llave pública y privada del CA (pasword sesamo) (ojo con 
# el SHA256 )

do_NGINX_3() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  if [ -z "$ROOT_CA" ]; then
      whiptail --msgbox "Por favor corra el ejercicio 1 de NGINX\n" 20 60 2
      return
  fi    
  NGINX_3_LOG=''
  nx31=0
  nx32=0
  FILE_KEY="$(ls -1 $ROOT_CA/private/)"
  if [ -n "$FILE_KEY" ]; then
      EL_KEY_OK="$(openssl rsa -check -noout -in $ROOT_CA/private/$FILE_KEY -passin pass:sesamo|grep 'RSA key ok')"
      if [ -n "$EL_KEY_OK" ]; then
          nx31=1
          NGINX_3_LOG="La llave privada existe y $EL_KEY_OK\n"
      else 
          nx31=0
          NGINX_3_LOG="La llave privada existe pero no esta con password sesamo o es incorrecta"
      fi    
  else 
      nx31=0
      NGINX_3_LOG="No encuentro la llave Privada"
  fi    

  NOTA[17]=$(echo $nx31 + $nx32 | bc) 
  whiptail --msgbox "$NGINX_3_LOG \n\nNota parcial ${NOTA[17]}." 20 60 2
}  

# NGINX 4)
# Para genera un archivo CSR (Certificate Signing Request) del dominio 
# jhondoe.com se debe prepara un archivo de configuración : jhondoe.cnf, 
# con el sigiente detalle : (ojo , aquí deben usar su propio dominio y 
# remplazar su información que corresponda)
# commonName = www.jhondoe.com < -- el dominio asignado a cada alumno mas www>
# stateOrProvinceName = Santa Cruz
# countryName = BO
# emailAddress = jhon123@jhondoe.com < -- el correo real de cada alumno >
# organizationName = Jhon Doe < -- Nombre completo de cada alumno >
# organizationalUnitName = Diplomado infraestructura TI

do_NGINX_4() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  if [ -z "$ROOT_CA" ]; then
      whiptail --msgbox "Por favor corra el ejercicio 1 de NGINX\n" 20 60 2
      return
  fi    
  NGINX_4_LOG=''
  nx41=0
  nx42=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  NAME="$(echo $DESIRED_DOMAIN| cut -d '.' -f 1)"
  FILE_JHONDOE_CNF="$(ls -1 $ROOT_CA/ |grep 'cnf' | grep $NAME)"
  if [ -n FILE_JHONDOE_CNF ]; then
      nx41=0.5
      NGINX_4_LOG="El archivo de configuración se encuentra\n$FILE_JHONDOE_CNF\n"
      HAY_WWW="$(cat $ROOT_CA/$FILE_JHONDOE_CNF|grep -i 'commonName'|grep $DESIRED_DOMAIN)"
      if [ -n "$HAY_WWW" ]; then
          nx42=0.5
          NGINX_4_LOG="$NGINX_4_LOG\n Y se encuentra en commonName correcto\n $HAY_WWW\n"
      else 
         nx42=0
         NGINX_4_LOG="$NGINX_4_LOG\n El commonName no es correcto"
      fi   
  else 
      nx41=0
      nx42=0
      NGINX_4_LOG="$NGINX_4_LOG\n No encuentro el archivo de configuración $NAME"
  fi
  NOTA[18]=$(echo $nx41 + $nx42 | bc) 
  whiptail --msgbox "$NGINX_4_LOG \n\nNota parcial ${NOTA[18]}." 20 60 2
}  

#NGINX 5)
# Con la configuración de jhondoe.cnf, generar un CSR por 1 año (pasword sesamo)

do_NGINX_5() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  if [ -z "$ROOT_CA" ]; then
      whiptail --msgbox "Por favor corra el ejercicio 1 de NGINX\n" 20 60 2
      return
  fi    
  NGINX_5_LOG=''
  nx51=0
  nx52=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  MY_CSR="$(find $ROOT_CA -type f -name '*.pem' -exec grep -iH 'BEGIN CERTIFICATE REQUEST'  {} \;|cut -d ':' -f 1)"

  if [ -n "$MY_CSR" ]; then
      nx51=0.5
      NGINX_5_LOG="El Certificate Signing Request existe\n $MY_CSR\n "
      MY_CSR_OK="$(openssl req -text -noout -in $MY_CSR | grep www.$DESIRED_DOMAIN)"
      if [ -n "$MY_CSR_OK " ]; then
          nx52=0.5
          NGINX_5_LOG="$NGINX_5_LOG\n El CSR esta correcto\n $MY_CSR_OK "
      else 
          nx52=0
          NGINX_5_LOG="$NGINX_5_LOG\n El CSR no esta correcto\n "
      fi    
  else
      nx51=0
      nx52=0
      NGINX_5_LOG="No encuentro ningún Certificate Signing Request "
  fi    

  NOTA[19]=$(echo $nx51 + $nx52 | bc) 
  whiptail --msgbox "$NGINX_5_LOG \n\nNota parcial ${NOTA[19]}." 20 60 2
}  

# NGINX 6)
# Luego con la configuración de CA (caconfig.cnf) firmar y genera el certificado SSL
do_NGINX_6() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  if [ -z "$ROOT_CA" ]; then
      whiptail --msgbox "Por favor corra el ejercicio 1 de NGINX\n" 20 60 2
      return
  fi    
  nx61=0
  nx62=0
  NGINX_6_LOG=''
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  MY_SING_CERT="$(find $ROOT_CA/signedcerts -type f -exec grep -i Subject {} \;)"
  MY_SING_CERT_OK="$(echo $MY_SING_CERT | grep www.$DESIRED_DOMAIN)"

  if [ -n "$MY_SING_CERT_OK" ]; then
      nx61=1
      NGINX_6_LOG="El Certificado esta firmado y su Subjet es\n\n $MY_SING_CERT_OK \n"
  else 
      nx61=0
      NGINX_6_LOG="No encuentro un certificado firmado\n"
  fi    
  NOTA[20]=$(echo $nx61 + $nx62  | bc) 
  whiptail --msgbox "$NGINX_6_LOG \n\nNota parcial ${NOTA[20]}." 20 60 2
}  

# NGINX 7)
# En el paso 6 ya se crearon la llave privada y el certificado del servidor 
# www.jhondoe.com estos deben ser adecuados para que el NGINX los utilice :
# Quitar el password a la llave privada
# Crear un archivo crt a partir de el archivo pem
# Y crear el archivo jhondoe.crt (boundle), con la unión del crt de mi dominio 
# y el crt del CA

do_NGINX_7() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  NGINX_7_LOG=''
  nx71=0
  nx72=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  NAME="$(echo $DESIRED_DOMAIN| cut -d '.' -f 1)"
  MY_SNIP_SSL_CONF="$(ls -1 /etc/nginx/snippets | grep $NAME)"

  if [ -n "$MY_SNIP_SSL_CONF" ]; then
      MY_JHONDOE_CRT="$(cat /etc/nginx/snippets/$MY_SNIP_SSL_CONF | grep crt| cut -d ' ' -f2| cut -d ';' -f 1)"
      MY_JHONDOE_KEY="$(cat /etc/nginx/snippets/$MY_SNIP_SSL_CONF | grep key| cut -d ' ' -f2| cut -d ';' -f 1)"
      MY_JHONDOE_CRT_OK="$(openssl crl2pkcs7 -nocrl -certfile $MY_JHONDOE_CRT|openssl pkcs7 -print_certs -text -noout|grep 'Subject:')"

      if [ -n "$MY_JHONDOE_CRT_OK" ]; then 
          HAY_CN_WWW="$(echo $MY_JHONDOE_CRT_OK|grep -i 'www')"
          HAY_CN_ROOT="$(echo $MY_JHONDOE_CRT_OK|grep -i 'Root')"
          if [ -n "$HAY_CN_WWW" ] && [ -n "$HAY_CN_ROOT" ]; then
              nx71=0.5
              NGINX_7_LOG="El certificado boundle $MY_JHONDOE_CRT existe y esta OK\n$MY_JHONDOE_CRT_OK"
          else 
              nx71=0
              NGINX_7_LOG="El certificado boundle $MY_JHONDOE_CRT no es correcto"
          fi    
      else   
          nx71=0
          NGINX_7_LOG="El certificado boundle $MY_JHONDOE_CRT no es correcto"
      fi    
      MY_JHONDOE_KEY_OK="$( openssl rsa -in $MY_JHONDOE_KEY  -check|grep 'RSA key ok')"
      if [ -n "$MY_JHONDOE_KEY_OK" ]; then
          nx72=0.5
          NGINX_7_LOG="$NGINX_7_LOG\n\n La llave privada existe y esta OK"
      else 
          nx72=0
          NGINX_7_LOG="$NGINX_7_LOG\n\n La llave privada no es correcta"
      fi    
  else 
      nx71=0
      nx72=0
      NGINX_7_LOG="No encuentro los certificados de $DESIRED_DOMAIN"
  fi    

  NOTA[21]=$(echo $nx71 + $nx72    | bc) 
  whiptail --msgbox "$NGINX_7_LOG \n\nNota parcial ${NOTA[21]}." 20 60 2
}  




# NGINX 8)
# Configurar los snippets (pedazos) de configuración ssl (ssl-params.conf) y 
# path de los certificados (jhondoe.conf)
do_NGINX_8() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  NGINX_8_LOG=''
  nx81=0
  nx82=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  NAME="$(echo $DESIRED_DOMAIN| cut -d '.' -f 1)"
  MY_SNIP_SSL_CONF="$(ls -1 /etc/nginx/snippets | grep $NAME)"
  MY_SNIP_SSL_PARAM_CONF="$(ls -1 /etc/nginx/snippets | grep -i 'ssl-params.conf')" 

  if [ -n "$MY_SNIP_SSL_PARAM_CONF" ]; then 
      nx81=0.5
      NGINX_8_LOG=" El archivo ssl-params.conf existe"
  else
      nx81=0
      NGINX_8_LOG=" El archivo ssl-params.conf no existe"
  fi    
  if [ -n "$MY_SNIP_SSL_CONF" ]; then
      nx82=0.5
      NGINX_8_LOG="$NGINX_8_LOG\n\n El archivo de path de certificados existe"
  else
      nx82=0
      NGINX_8_LOG="$NGINX_8_LOG\n\n El archivo de path de certificados no existe"
  fi    
  NOTA[22]=$(echo $nx81 + $nx82   | bc) 
  whiptail --msgbox "$NGINX_8_LOG \n\nNota parcial ${NOTA[22]}." 20 60 2
}  


# NGINX 9)
# Configurar el virtual host de nginx para el nombre de servidor www.jhondoe.com, con ayuda de los snippets

do_NGINX_9() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  NGINX_9_LOG=''
  nx91=0
  nx92=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  NAME="$(echo $DESIRED_DOMAIN| cut -d '.' -f 1)"
  MY_VIRTUAL_HOST="$(ls -1 /etc/nginx/sites-enabled | grep $NAME)"

  if [ -n "$MY_VIRTUAL_HOST" ]; then 
      nx91=0.5
      NGINX_9_LOG="El archivo de virtual Host existe"
      MY_VIRTUAL_HOST_OK="$(cat /etc/nginx/sites-enabled/$MY_VIRTUAL_HOST | grep 'server_name' | grep www.$DESIRED_DOMAIN)"
      if [ -n "$MY_VIRTUAL_HOST_OK" ]; then 
          nx92=0.5
          NGINX_9_LOG="$NGINX_9_LOG\n\n Y corresponde  a www.$DESIRED_DOMAIN"
      else
          NGINX_9_LOG="$NGINX_9_LOG\n\n Pero no corresponde  a www.$DESIRED_DOMAIN"
          nx92=0
      fi    
  else
      NGINX_9_LOG="El archivo de virtual Host no existe"
      nx91=0
  fi     
  NOTA[23]=$(echo $nx91 + $nx92   | bc) 
  whiptail --msgbox "$NGINX_9_LOG \n\nNota parcial ${NOTA[23]}." 20 60 2
}  

#NGINX 10)
# Crear una página html de bienvenida (hola mundo) que responda a la 
# petición https://www.jhondoe.com

do_NGINX_10() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  NGINX_10_LOG=''
  nx101=0
  nx102=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  NAME="$(echo $DESIRED_DOMAIN| cut -d '.' -f 1)"
  MY_VIRTUAL_HOST="$(ls -1 /etc/nginx/sites-enabled | grep $NAME)"
  if [ -n "$MY_VIRTUAL_HOST" ]; then 
      MY_VIRTUAL_HOST_ROOT="$(cat /etc/nginx/sites-enabled/$MY_VIRTUAL_HOST | grep root |awk '{ print $2} ' |cut -d ';' -f1)"
      if [ -n "$MY_VIRTUAL_HOST_ROOT" ]; then
          HAY_FILE_HTML="$(ls -1 $MY_VIRTUAL_HOST_ROOT )" 
          if [ -n "$HAY_FILE_HTML" ]; then 
              ES_HTML="$(file $MY_VIRTUAL_HOST_ROOT/$HAY_FILE_HTML| grep 'HTML document')"
              if [ -n "$ES_HTML" ]; then
                  nx101=1
                  NGINX_10_LOG="El archivo HTML (página web) existe"
              else
                  nx101=0
                  NGINX_10_LOG="El archivo HTML (página web) no existe"
              fi    
          else 
              nx101=0
              NGINX_10_LOG"=El archivo HTML (página web) no existe"
          fi     
      else     
          nx101=0
          NGINX_10_LOG="El archivo HTML (página web) no existe"
      fi    
  else   
      nx101=0
      NGINX_10_LOG="El archivo de virtual Host no existe"
  fi
  NOTA[24]=$(echo $nx101 + $nx102   | bc) 
  whiptail --msgbox "$NGINX_10_LOG \n\nNota parcial ${NOTA[24]}." 20 60 2
}  

# NGINX 11)
# Verificar todo con el comando nginx -t
do_NGINX_11() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  NGINX_11_LOG=''
  nx111=0
  nx112=0
  MY_TEST="$(nginx -t 2>&1|grep 'test is successful')"

  if [ -n "$MY_TEST" ]; then
      nx111=1
      NGINX_11_LOG="El test es satisfactorio \n $MY_TEST "
  else
      nx111=0
  fi    
  NOTA[25]=$(echo $nx111 + $nx112   | bc) 
  whiptail --msgbox "$NGINX_11_LOG \n\nNota parcial ${NOTA[25]}." 20 60 2
}  

# NGINX 12)
# Por último reiniciar el servidor Nginx y verificar que todo funciona
# Si se navega por IP debe responder la pagina por defecto
# Si se navega https://www.jhondoe.com, debe mostrarse la página que se creó
# en el paso 10 (el navegador no podrá verificar la autenticidad del 
# certificado auto firmado por lo que se debe incluir como excepción en el navegador)
# Si se navega http://www.jhondoe.com, debe mostrarse la página que se creó en el paso 10

do_NGINX_12() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
  NGINX_12_LOG=''
  nx121=0
  nx122=0
  DESIRED_DOMAIN=${DATA[3]}
  DESIRED_DOMAIN="$(echo -e "${DESIRED_DOMAIN}" | tr -d '[:space:]')"
  MY_HTTPS="$(curl -s -k www.$DESIRED_DOMAIN)" 
  MY_OK_1=$?
  if [ -n "$MY_HTTPS" ] && [ "$MY_OK_1" -eq '0'  ]; then 
      nx121=0.5
      NGINX_12_LOG="El servicio de https es OK"
  else 
      nx121=0
      NGINX_12_LOG="El servicio de https tiene un problema "
  fi    
  MY_HTTP="$(curl -s -L -k www.$DESIRED_DOMAIN )" 
  MY_OK_2=$?
  if [ -n "$MY_HTTP" ] && [ "$MY_OK_2" -eq '0'  ]; then 
      nx122=0.5
      NGINX_12_LOG="$NGINX_12_LOG\n\nEl servicio de http es OK"
  else
      nx122=0
      NGINX_12_LOG="$NGINX_12_LOG\n\nEl servicio de http tiene un problema "
  fi    
  NOTA[26]=$(echo $nx121 + $nx122   | bc) 
  whiptail --msgbox "$NGINX_12_LOG \n\nNota parcial ${NOTA[26]}." 20 60 2
}  

do_select() {
 let i=0 # define counting variable
 let j=0 # define counting variable
 W=() # define working array
 while read -r line; do # process file by line
    let i=$i+1
    W+=($i "$line")
 done < <( cat ./dominios.txt| awk -F"|" '{print $2}' )
 FILE=$(whiptail --title "Lista de Alumnos " --backtitle "$BACKTITLE" --menu "Elije tu nombre" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT "${W[@]}" 3>&2 2>&1 1>&3) # show dialog and store output
 if [ $? -eq 0 ]; then # Exit with OK
    alumno=` cat $DATAFILE | grep "^$FILE "`
    OIFS=$IFS
    IFS='|'
    ALUMNOS=$alumno
    for x in $ALUMNOS
    do 
        let j=$j+1
        DATA[j]=$x
        echo "${DATOS[$j]}"
    done    
 fi    
}


do_about() {
  whiptail --msgbox "\
Esta herramienta esta diseñada para revisar las configuraciones 
de las practicas/exámenes  del diplomado de Infraestructura  TI
en la Nube con Software Libre,  Modulo de Seguridad y Hardening
Cada opción  revisara  una  parte de la  práctica, y anotara el 
resultado en memoria y lo mostrara al alumno.

Primero debes identificarte en la lista de alumnos para que  la
herramienta pueda comprobar la asignación

Después de correr todas  las opciones de revisión, se puede ver
la nota final antes de generar un archivo cifrado que contendrá
el resultado final.

Por último este archivo debe ser enviado por correo electrónico
a la dirección diplomado@verastegui.net y subido a la plataforma\
" 22 72 1
  return 0
}



if [ "$INTERACTIVE" = True ]; then
    calc_wt_size
while true; do
    FUN=$(whiptail --title "Herramienta de exanimación de configuraciones  (examina)" --backtitle "$BACKTITLE" --menu "Opciones" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Terminar --ok-button Seleción \
        "1 Instrucciones" "Como utilizar este programa"\
        "2 Seleccionar Alumno" "Seleccionar tu nombre de la lista"\
        "3 Correr Todo " "Correr todas las comprobaciones del examen"\
        "4 DNS 1) " " Revisar el punto 1 de la instrucción DNS"  \
        "5 DNS 2) " " Revisar el punto 2 de la instrucción DNS"  \
        "6 DNS 3) " " Revisar el punto 3 de la instrucción DNS"  \
        "7 DNS 4) " " Revisar el punto 4 de la instrucción DNS"  \
        "8 DNS 5) " " Revisar el punto 5 de la instrucción DNS"  \
        "9 DNS 6) " " Revisar el punto 6 de la instrucción DNS"  \
        "10 DNS 7) " " Revisar el punto 7 de la instrucción DNS"  \
        "11 DNS 8) " " Revisar el punto 8 de la instrucción DNS"  \
        "12 DNS 9) " " Revisar el punto 9 de la instrucción DNS"  \
        "13 DNS 10) " " Revisar el punto 10 de la instrucción DNS"  \
        "14 DNS 11) " " Revisar el punto 11 de la instrucción DNS"  \
        "15 DNS 12) " " Revisar el punto 12 de la instrucción DNS"  \
        "16 DNS 13) " " Revisar el punto 13 de la instrucción DNS"  \
        "17 DNS 14) " " Revisar el punto 14 de la instrucción DNS"  \
        "18 NGINX 1) " " Revisar el punto 1 de la instrucción NGINX"  \
        "19 NGINX 2) " " Revisar el punto 2 de la instrucción NGINX"  \
        "20 NGINX 3) " " Revisar el punto 3 de la instrucción NGINX"  \
        "21 NGINX 4) " " Revisar el punto 4 de la instrucción NGINX"  \
        "22 NGINX 5) " " Revisar el punto 5 de la instrucción NGINX"  \
        "23 NGINX 6) " " Revisar el punto 6 de la instrucción NGINX"  \
        "24 NGINX 7) " " Revisar el punto 7 de la instrucción NGINX"  \
        "25 NGINX 8) " " Revisar el punto 8 de la instrucción NGINX"  \
        "26 NGINX 9) " " Revisar el punto 9 de la instrucción NGINX"  \
        "27 NGINX 10) " " Revisar el punto 10 de la instrucción NGINX"  \
        "28 NGINX 11) " " Revisar el punto 11 de la instrucción NGINX"  \
        "29 NGINX 12) " " Revisar el punto 12 de la instrucción NGINX"  \
        "30 Resultados" "Mostrar los resultados de la revisión" \
        "31 Crear archivo " "Crear el archivo final cifrado" \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      exit 0;
    elif [ $RET -eq 0 ]; then
        case "$FUN" in
            1\ *) do_about  ;;
            2\ *) do_select ;;
            3\ *) do_todos  ;;
            4\ *) do_DNS_1  ;;
            5\ *) do_DNS_2  ;;
            6\ *) do_DNS_3  ;;
            7\ *) do_DNS_4  ;;
            8\ *) do_DNS_5  ;;
            9\ *) do_DNS_6  ;;
            10\ *) do_DNS_7  ;;
            11\ *) do_DNS_8  ;;
            12\ *) do_DNS_9  ;;
            13\ *) do_DNS_10  ;;
            14\ *) do_DNS_11  ;;
            15\ *) do_DNS_12  ;;
            16\ *) do_DNS_13  ;;
            17\ *) do_DNS_14  ;;
            18\ *) do_NGINX_1  ;;
            19\ *) do_NGINX_2  ;;
            20\ *) do_NGINX_3  ;;
            21\ *) do_NGINX_4  ;;
            22\ *) do_NGINX_5  ;;
            23\ *) do_NGINX_6  ;;
            24\ *) do_NGINX_7  ;;
            25\ *) do_NGINX_8  ;;
            26\ *) do_NGINX_9  ;;
            27\ *) do_NGINX_10  ;;
            28\ *) do_NGINX_11  ;;
            29\ *) do_NGINX_12  ;;
            30\ *) do_suma  ;;
            31\ *) do_resultado ;;
            *) whiptail --msgbox "Error de programa: opción desconocida" 20 60 1 ;;
        esac ||  whiptail --msgbox "Ocurrió un error ejecutando la opción $FUN" 20 60 1
     else    
       exit 1
     fi  
 done     
fi
