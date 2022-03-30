#!/bin/bash
export LC_ALL=C.UTF-8
# A Menu driver Configuration test system 
# PARA EL SEGUNDO EXAMEN
INTERACTIVE=True
BACKTITLE="U.A.G.R.M SCHOOL OF ENGINEERING, DIPLOMADO EN INFRAESTRUCTURA TI EN LA NUBE, SEGURIDAD Y HARDENING EN GNU/LINUX"
DATAFILE="./dominios.txt"
DATA=()
NOTA=()
SPIP=()
ROOT_CA=''
DIRECTORIO_RESULTADO="/tmp/Examen2"
PUBKEY="./public.pem"
FILE_TO_VERIFY="./examina.sh"
SIGNATURE_FILE="./firma.dat"
NOTA_TOTAL=0
#DEBUG
#set -x
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
        NOTA_FINAL="$(echo "scale=10;40/29*$NOTA_TOTAL" | bc)"
        NOTA_FINAL="$(printf %.$2f $NOTA_FINAL)"
        whiptail --msgbox " Estimado Alumno ${DATA[2]}\n\n Tu Nota Total es: $NOTA_TOTAL\n\n Y tu NOTA FINAL es $NOTA_FINAL sobre 40 Puntos." 20 60 2
    fi    
}

do_resultado(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi 
    openssl base64 -d -in $SIGNATURE_FILE -out /tmp/sign.sha256
    VERIFI="$(openssl dgst -sha256 -verify $PUBKEY -signature /tmp/sign.sha256 $FILE_TO_VERIFY)"
    rm -f /tmp/sign.sha256
    IS_OK="$(echo $VERIFI |grep 'OK')"
  if [ -n "$IS_OK" ]; then
      mkdir -p $DIRECTORIO_RESULTADO
      cp -a /etc $DIRECTORIO_RESULTADO/
      cp $FILE_TO_VERIFY $DIRECTORIO_RESULTADO/
      do_suma;
      MY_NOTA="${DATA[2]} , $NOTA_FINAL"
      whiptail --yesno "Estimado ${DATA[2]}, esta seguro de crear el archivo de resultado\nSu nota es $NOTA_FINAL?" $DEFAULT 20 60 2
      RET=$?
      if [ $RET -eq 0 ]; then
          ENCRYPT="$(echo $MY_NOTA|openssl  pkeyutl -encrypt -pubin -inkey $PUBKEY -out $DIRECTORIO_RESULTADO/xyz.dat )"    
          tar czf /tmp/examen2.tar.gz $DIRECTORIO_RESULTADO 2>/dev/null
          RET1=$?
          rm -rf $DIRECTORIO_RESULTADO
          if [ $RET1 -eq 0 ]; then 
              whiptail --msgbox "El archivo /tmp/examen2.tar.gz esta listo para ser enviado \n" 20 60 2
          else
              whiptail --msgbox "Ocurrió  un error al generar el  archivo de resultados \n" 20 60 2
          fi    
      fi    
  else
      whiptail --msgbox "Ocurrió  un error se encontró un cambio en el script por favor vuela a copiarlo  \n" 20 60 2
  fi 

}


do_todos() {
    do_tarea_1;
    do_tarea_2;
    do_tarea_3;
    do_tarea_4;
    do_tarea_5;
    do_tarea_6;
    do_tarea_7;
    do_tarea_8;
   
    do_suma;

}

# tarea 1)
# En el archivo sysctl.con.example se encuentra una configuración avanzada de 
# parámetros del kernel (seguridad mas optimización de tcp para servidores con carga).
# este debe ser copiado al directorio /etc/sysctl.d/ con el nombre de local.conf 
# (/etc/sysctl.d/local.conf).
# 

do_tarea_1() {
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  nt01=0
  nt02=0
  tarea_1_LOG=''
  ARCHIVO_1='/etc/sysctl.d/local.conf'
  W=0
  i=0
  if [ -f "$ARCHIVO_1" ]; then
    nt01=1
    tarea_1_LOG="El archivo /etc/sysctl.d/local.conf existe\n"
    while read -r line; do # process file by line
        TEST_SCTL=$(sysctl -a | grep "$line" )  
        if [ -n "$TEST_SCTL" ]; then 
         let i=$i+1
         W=$(echo $i)
        fi
    done < <( cat  "$ARCHIVO_1" | grep -v '^#'| grep '\S' )
    if [ "$W" -ge 30 ]; then 
      nt02=1
      tarea_1_LOG="$tarea_1_LOG\n\n Todos los parámetros de kernel están cargados"
    else
      tarea_1_LOG="$tarea_1_LOG\n\n No todos Los parámetros de kernel están cargados"   
      nt02=0  
    fi  
  else 
     tarea_1_LOG="El archivo /etc/sysctl.d/local.conf no existe\n" 
     nt01=0    
  fi  
  NOTA[1]=$(echo $nt01  + $nt02| bc)
  whiptail --msgbox "$tarea_1_LOG \n\nNota parcial ${NOTA[1]}." 20 60 2
}

# tarea 2)
# En el archivo local.conf se encuentra la definición de limites para todos (*) 
# los usuarios del servidor, este debe ser copiado en /etc/security/limits.d/ 
# verificar que se aplica con el comando ulimit -a

do_tarea_2(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  nt21=0
  nt22=0
  tarea_2_LOG=''
  #Comprobar que existe el archivo
  ARCHIVO_2='/etc/security/limits.d/local.conf'
  if [ -f "$ARCHIVO_2" ]; then
     nt21=1 
     tarea_2_LOG="El archivo /etc/security/limits.d/local.conf existe\n"
     TEST_SCTL1="$(ulimit -Ha |grep 32768)"
     if [ -n "$TEST_SCTL1" ]; then
        nt22=1
        tarea_2_LOG="$tarea_2_LOG\n Y esta aplicado"
     else
        nt22=0
        tarea_2_LOG="$tarea_2_LOG\n Pero no párese estar aplicado"
     fi 
  else
    tarea_2_LOG="El archivo /etc/security/limits.d/local.conf no existe\n" 
    nt21=0 
  fi
    NOTA[2]=$(echo $nt21 + $nt22 | bc)
  whiptail --msgbox "$tarea_2_LOG \n\n Nota parcial ${NOTA[2]}." 20 60 2
}

# tarea 3)
# Instalar el sistema de auditoria AIDE y ejecutarlo por primera vez (aide -v) 
# inicializar la base de datos (checksum de todos los archivos del sistema). 
# Verificar que todo el proceso termine correctamente. copiar el archivo de 
# configuración en /etc/aide/aide.conf. Por ultimo generar un archivo de cambios 
# con la instrucción: aide -c /etc/aide/aide.conf --check >/root/cambios.txt

do_tarea_3(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  nt31=0
  nt32=0
  nt33=0
  tarea_3_LOG=''
  ESTA_INSTALADO="$(sudo dpkg -l |grep ii|grep aide |grep static)"
  if [ -n "$ESTA_INSTALADO" ]; then
     nt31=1
     tarea_3_LOG="Se encontró AIDE instalado\n"
     ESTA_DOWNLOAD="$(cat /etc/aide/aide.conf|grep 'this file is generated dynamically from')"
     if [ -n "$ESTA_DOWNLOAD" ]; then 
        tarea_3_LOG="$tarea_3_LOG\n\n Esta inicializado\n"
        nt32=1 
        HARA_REPORTE="$(cat /root/cambios.txt |grep 'database')"
        if [ -n "$HARA_REPORTE" ]; then
           nt33=1
           tarea_3_LOG="$tarea_3_LOG\n\n Y el reporte de cambios esta en /root/cambios.txt\n"
        else
           nt33=0
           tarea_3_LOG="$tarea_3_LOG\n\n Pero no existe un reporte de cambios en /root/cambios.txt\n"    
        fi
     else
        nt32=0
        tarea_3_LOG="$tarea_3_LOG\n\n Pero no esta inicializado\n"
     fi
  else
     tarea_3_LOG="No Se encontró AIDE instalado\n"   
     nt31=0
  fi
   
  NOTA[3]=$(echo $nt31 + $nt32 + $nt33 | bc)
  whiptail --msgbox "$tarea_3_LOG \n\nNota parcial ${NOTA[3]}." 20 60 2
}

# tarea 4)
# Ejecutar la auditoria de Seguridad OpenSCAP :
#    sudo apt install -y libopenscap8
#    wget https://security-metadata.canonical.com/oval/com.ubuntu.$(lsb_release -cs).usn.oval.xml.bz2
#    bunzip2 com.ubuntu.$(lsb_release -cs).usn.oval.xml.bz2
#    sudo oscap oval eval --report /root/report.html com.ubuntu.$(lsb_release -cs).usn.oval.xml
#    Verificar que se genera el reporte en /root/report.html


do_tarea_4(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  nt41=0
  nt42=0
  nt42=0
  tarea_4_LOG=''
  ARCHIVO_XML="com.ubuntu.$(lsb_release -cs).usn.oval.xml"
  ESTA_INSTALADO="$(sudo dpkg -l |grep ii|grep 'libopenscap')"
  if [ -n "$ESTA_INSTALADO" ]; then
     nt41=1
     tarea_4_LOG="Se encontró libopenscap instalado\n"
     ESTA_DOWNLOAD="$(find /  -type f |grep $ARCHIVO_XML)" 
     if [ -n "$ESTA_DOWNLOAD" ]; then 
        tarea_4_LOG="$tarea_4_LOG\n\n El archivo XML esta descargado\n"
        nt42=1 
        HARA_REPORT="$(cat /root/report.html|grep 'OVAL Results Generator Information')"
        if [ -n "$HARA_REPORT" ]; then
           nt43=1
           tarea_4_LOG="$tarea_4_LOG\n\n Y el reporte esta en /root/report.html\n"
        else
           nt43=0
           tarea_4_LOG="$tarea_4_LOG\n\n Pero no existe un reporte en /root/report.html\n"    
        fi
     else
        nt42=0
        tarea_4_LOG="$tarea_4_LOG\n\n Pero no se encuentra el archivo XML \n"
     fi
  else
     tarea_4_LOG="No Se encontró libopenscap instalado\n"   
     nt41=0
  fi

  
  NOTA[4]=$(echo $nt41 + $nt42 + $nt43| bc) 
  whiptail --msgbox "$tarea_4_LOG \n\nNota parcial ${NOTA[4]}." 20 60 2
}

# tarea 5)
# Crear tres cuantas de usuario dentro del servidor Linux con las siguientes características: (todos con password sesamo)
#   Usuario: soporte1
#       El Usuario debe cambiar su contraseña en la siguiente login exitoso.
#       Fecha de Expiración 31 De diciembre de 2022
#       Maximá duración de la contraseña (días antes que la contraseña expire) 90 (tres meses)
#   Usuario: admin
#       El Usuario debe cambiar su contraseña en la siguiente login exitoso.
#       Fecha de Expiración 31 De diciembre de 2024
#       Máxima duración de la contraseña (días antes que la contraseña expire) 90 (tres meses)
#       El usuario debe tener permisos de admin (ser parte del grupo sudo)
#   Usuario: siso
#       El Usuario debe cambiar su contraseña en la siguiente login exitoso.
#       Fecha de Expiración 31 De diciembre de 2024
#       Máxima duración de la contraseña (días antes que la contraseña expire) 90 (tres meses)


do_usuario(){
    local my_USUARIO=$1
    local my_FECHA=$2
    local my_SUDO=$3
    LISTA_USER="$(getent passwd {1000..2000})"
    HAY_USUARIO="$(echo $LISTA_USER|grep $my_USUARIO)" 
    if [ -n "$HAY_USUARIO" ]; then
       n1=0
       n2=0
       n3=0
       LISTA_CHAGE="$(chage -l -i $my_USUARIO)"
       FECHA_OK="$(chage -l -i $my_USUARIO | grep "$my_FECHA")"
       M_CHANGE="$(chage -l -i $my_USUARIO | grep '90')"
       
       if [ "$my_SUDO" -eq  1 ]; then
          ES_SUDO="$(groups $my_USUARIO | grep 'sudo')" 
          if [ -n "$ES_SUDO" ]; then 
            n3=1  
          else
            n3=0 
          fi 
        else
           n3=1   
        fi

        if [ -n "$FECHA_OK" ]; then
            n2=1
        else
            n2=0
        fi

        if [ -n "$M_CHANGE" ]; then
           n1=1     
        else
           n1=0
        fi
        nt="$(echo $n1 + $n2 + $n3 | bc)"
        if [ "$nt" -eq '3' ]; then 
            return 3
        else
            return 0
        fi    
    else
     whiptail --msgbox "No se encontró al usuario my_USUARIO\n" 20 60 2 
     return 0
    fi 
}
do_tarea_5(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  usu=0
  tarea_5_LOG="Se reviso la configuración de los usuarions\n"
  do_usuario "soporte1" "2022-12-31" "0"
  nt51=$?
  if [ $nt51 -gt 0 ]; then 
     usu=1
  fi   
  do_usuario "admin" "2024-12-31" "1"
  nt52=$?
  if [ $nt52 -gt 0 ]; then 
     let usu=$usu+1
  fi   
  do_usuario "siso" "2024-12-31" "0"
  nt53=$?
  if [ $nt53 -gt 0 ]; then 
     let usu=$usu+1
  fi   
  tarea_5_LOG="$tarea_5_LOG\n Y se encontró  $usu de 3 usuarios requeridos y bien configurados"
  
  NOTA[5]=$(echo $nt51 + $nt52 + $nt53 | bc) 
  whiptail --msgbox "$tarea_5_LOG \n\nNota parcial ${NOTA[5]}." 20 60 2
}

# tarea 6)
# SISO: normalmente se denomina al Senior Information security officer, necesita 
# revisar reportes regulares que el usuario soporte1 genera. para esto se debe:
#   El usuario siso creara una carpeta en su home (/home/siso) llamada REPORTES 
#   (todo mayúsculas).
#   Este directorio debe tener acl (listas de acceso) de modo que el usuario 
#   soporte1 pueda ingresar al directorio del usuario siso y pueda crear sus 
#   reportes en este directorio (/home/siso/REPORTES).
#   como prueba de esto pude ejecutar como usuario reporte1 
#   touch /home/siso/REPORTES/Reporte1.txt


do_tarea_6(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  tarea_6_LOG=""
  nt61=0
  nt62=0
  nt63=0
  ARCHIVO_6="/home/siso/REPORTES"
  if [ -d "$ARCHIVO_6" ]; then 
    nt61=1
    tarea_6_LOG=" El directorio $ARCHIVO_6 existe\n"
    HAY_ACL="$(getfacl $ARCHIVO_6|grep 'soporte1')"
    if [ -n "$HAY_ACL" ]; then 
        nt62=1
        tarea_6_LOG="$tarea_6_LOG El ACL $HAY_ACL existe\n"
    else
        nt62=0
        tarea_6_LOG="$tarea_6_LOG El ACL $HAY_ACL NO existe\n"
    fi
    ARCHIVO_6_R="/home/siso/REPORTES/Reporte1.txt"
    if [ -f "$ARCHIVO_6_R" ]; then 
        nt63=1
        tarea_6_LOG="$tarea_6_LOG El archivo $ARCHIVO_6_R existe\n"
    else
        nt63=0
        tarea_6_LOG="$tarea_6_LOG El archivo $ARCHIVO_6_R NO existe\n"
    fi    
  else  
    nt61=0
    tarea_6_LOG="El directorio $ARCHIVO_6 NO existe\n"
  fi
  
  NOTA[6]=$(echo $nt61 + $nt62 +$nt63| bc)
  whiptail --msgbox "$tarea_6_LOG \n\nNota parcial ${NOTA[6]}." 20 60 2
}

# tarea 7)
# Habilitar AppArmor en el servidor y adicionar el profile usr.sbin.nginx. 
# Colocar al nginx en modo enforced con APPArmor (sudo aa-enforce nginx) 
# Crear el directorio /var/www/html/unsafe y verificar que no es posible 
# acceder al mismo
do_tarea_7(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  tarea_7_LOG=''
  nt71=0
  nt72=0
  nt73=0
  ARCHIVO_PROFILE="/etc/apparmor.d/usr.sbin.nginx"
  if [ -f "$ARCHIVO_PROFILE" ]; then
    nt71=1
    tarea_7_LOG=" El profile $ARCHIVO_PROFILE existe"
    ENFORCE="$(aa-status | grep nginx)"
    if [ -n "$ENFORCE" ]; then 
      nt72=1
      tarea_7_LOG="$tarea_7_LOG\n\n El nginx esta corriendo en  enforce mode\n $ENFORCE "
    else
      nt72=0          
      tarea_7_LOG="$tarea_7_LOG\n\n El nginx NO esta corriendo en  enforce mode\n "
    fi
    NO_ACCE="$(curl -s  http://$IP/unsafe/|grep '403 Forbidden')"    
    if [ -n "$NO_ACCE" ]; then
      nt73=1
      tarea_7_LOG="$tarea_7_LOG\n\n El acceso a http://$IP/unsafe/ esta denegado\n$NO_ACCE "
    else
      nt73=0
    fi    
  else
    tarea_7_LOG="El profile $ARCHIVO_PROFILE NO existe"
    nt71=0
  fi
  NOTA[7]=$(echo $nt71 + $nt72 + $nt73 | bc)
  whiptail --msgbox "$tarea_7_LOG \n\nNota parcial ${NOTA[7]}." 20 60 2
}

# tarea 8
# Habilitar el Firewall de Linux ubuntu, ufw y habilitar los puertos 
# tcp 80 443 y 22
do_tarea_8(){
  if [ ${#DATA[@]} -lt 1 ]; then 
      whiptail --msgbox "Por favor seleccione un alumno\n" 20 60 2
      return
  fi    
  tarea_8_LOG=''
  nt81=0
  nt82=0
  nt83=0
  nt84=0
  
  UFW_ENABLE="$(ufw status|grep -i 'active')"
  if [ -n "$UFW_ENABLE" ]; then 
    tarea_8_LOG=" El firewall ufw está activo\n" 
    nt81=1
    PORT_22="$(ufw status|grep 'ALLOW' |grep -i '22/tcp')"
    if [ -n "$PORT_22" ]; then 
        nt82=1
        tarea_8_LOG="$tarea_8_LOG\n El puerto 22 esta permitido \n"
    else
        nt82=0
        tarea_8_LOG="$tarea_8_LOG\n El puerto 22 NO esta permitido \n"
    fi
    PORT_80="$(ufw status|grep 'ALLOW' |grep -i '80/tcp')"
    if [ -n "$PORT_80" ]; then 
        nt83=1
        tarea_8_LOG="$tarea_8_LOG\n El puerto 80 esta permitido \n"
    else
        nt83=0
        tarea_8_LOG="$tarea_8_LOG\n El puerto 80 NO esta permitido \n"
    fi
    PORT_443="$(ufw status|grep 'ALLOW' |grep -i '443/tcp')"
    if [ -n "$PORT_443" ]; then 
        nt84=1
        tarea_8_LOG="$tarea_8_LOG\n El puerto 443 esta permitido \n"
    else
        nt84=0
        tarea_8_LOG="$tarea_8_LOG\n El puerto 443 NO esta permitido \n"
    fi
    
  else
    tarea_8_LOG=" El firewall ufw NO está activo\n" 
    nt81=0
  fi    
  
  
  NOTA[8]=$(echo $nt81 + $nt82 + $nt83 + $nt84 | bc)
  whiptail --msgbox "$tarea_8_LOG \n\nNota parcial ${NOTA[8]}." 20 60 2
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
    FUN=$(whiptail --title "Herramienta de exanimación de configuraciones  (examina 2)" --backtitle "$BACKTITLE" --menu "Opciones" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Terminar --ok-button Seleción \
    "1 Instrucciones" "Como utilizar este programa"\
    "2 Seleccionar Alumno" "Seleccionar tu nombre de la lista"\
    "3 Correr Todo " "Correr todas las comprobaciones del examen"\
    "4 Tarea 1) " " Revisar el punto 1 de las Tareas a ejecutar"  \
    "5 Tarea 2) " " Revisar el punto 2 de la Tareas a ejecutar"  \
    "6 Tarea 3) " " Revisar el punto 3 de la Tareas a ejecutar"  \
    "7 Tarea 4) " " Revisar el punto 4 de la Tareas a ejecutar"  \
    "8 Tarea 5) " " Revisar el punto 5 de la Tareas a ejecutar"  \
    "9 Tarea 6) " " Revisar el punto 6 de la Tareas a ejecutar"  \
    "10 Tarea 7) " " Revisar el punto 7 de la Tareas a ejecutar"  \
    "11 Tarea 8) " " Revisar el punto 8 de la Tareas a ejecutar" \
    "12 Resultados" "Mostrar los resultados de la revisión" \
    "14 Crear archivo " "Crear el archivo final cifrado" \
    3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      exit 0;
    elif [ $RET -eq 0 ]; then
        case "$FUN" in
            1\ *) do_about  ;;
            2\ *) do_select ;;
            3\ *) do_todos  ;;
            4\ *) do_tarea_1  ;;
            5\ *) do_tarea_2  ;;
            6\ *) do_tarea_3  ;;
            7\ *) do_tarea_4  ;;
            8\ *) do_tarea_5  ;;
            9\ *) do_tarea_6  ;;
            10\ *) do_tarea_7  ;;
            11\ *) do_tarea_8  ;;                                                                  
            12\ *) do_suma  ;;
            14\ *) do_resultado ;;
            *) whiptail --msgbox "Error de programa: opción desconocida" 20 60 1 ;;
        esac ||  whiptail --msgbox "Ocurrió un error ejecutando la opción $FUN" 20 60 1
     else    
       exit 1
     fi  
 done     
fi
