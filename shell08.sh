import os
import json
import requests
import secrets
from flask import request, session,abort
from .instance import config
from rich import print



class StoreOptions():
    # optimise it later
    neo = requests.session()
    client = requests.session()
    base_url = os.environ.get('BASE_URL')
    store_url = base_url + '/store/{}/'.format(os.environ.get('STORE_SLUG'))
    core_url = base_url + '/core'
    cart_url = store_url + 'carts/'
    discount_url = store_url + "discounts/"
    shipping_url = store_url + 'shipping-zones/state/'
    wishlist_url = base_url + \
        '/wishlist-filter/?store__slug={}'.format(
            os.environ.get('STORE_SLUG'))

    @staticmethod
    def generate_secret_key():
        generated_key = secrets.token_urlsafe(16)
        return generated_key
    

class StoreConnect():
    token_url = os.environ.get('BASE_URL') + '/connect/o/token/'
    revoke_token_url = os.environ.get('BASE_URL') + '/connect/o/revoke_token/'
    signup_url = os.environ.get('BASE_URL') + '/connect/signup/'
    connect_verification_url = os.environ.get('BASE_URL') + '/connect/verification/'
    

    @staticmethod
    def get_client_token(code, username, password):
        try:

            headers = {
                'Content-Type': 'application/json',
                'User-Agent': f'flask/requests/{os.environ.get("BACKEND_VERSION")}',
            }
            
            if code :
                # code authentication method for kio users
                if config.DEBUG:
                    redirect_uri = "http://" + request.host + "/signin"
                else:
                    redirect_uri = "https://" + request.host + "/signin"


                data = {
                    "client_id": os.environ.get('SUB_CLIENT_ID'),
                    "client_secret": os.environ.get('SUB_CLIENT_SECRET'),
                    "code": code,
                    "grant_type": "authorization_code",
                    "redirect_uri": redirect_uri
                }
                # print('code ======',data)
            
            if username != None and password != None :
                # password autghentication method for guest client
                data = {
                    "grant_type": "username",
                    "client_id": os.environ.get('CLIENT_ID'),
                    "username": username,
                }
                
            token = StoreOptions.client.post(
                StoreConnect.token_url, data=json.dumps(data), headers=headers)


            a_t = token.json()['access_token']
            r_t = token.json()['refresh_token']
            session["client_access_token"] = a_t

            StoreOptions.client.headers = {'Authorization': 'Bearer ' + a_t,
                                            'Content-Type': 'application/json',
                                            'Accept': 'application/json; version=2',
                                            'User-Agent': f'flask/requests/{os.environ.get("BACKEND_VERSION")}',
                                            }

        except:
            print("error in get token client")

    @staticmethod
    def revoke_client_token():
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': f'flask/requests/{os.environ.get("BACKEND_VERSION")}',
        }

        data = {
            "client_id": os.environ.get('SUB_CLIENT_ID'),
            "token":session["client_access_token"]
        }
        print('revoke data = ',data)
        revoke_token_request = requests.post(StoreConnect.revoke_token_url,data=json.dumps(data), headers=headers)
        
        print('revoke = ',revoke_token_request.status_code, revoke_token_request.text)
        if revoke_token_request.status_code == 200:
            StoreOptions.client.headers = {'Content-Type': 'application/json',
                                            'Accept': 'application/json; version=2',
                                            'User-Agent': f'flask/requests/{os.environ.get("BACKEND_VERSION")}',
                                            }
              


    
    
    @staticmethod
    def get_client_infos(code, username, password):
        
        # get client token
        StoreConnect.get_client_token(code, username, password)

        # get client infos
        user_url = StoreOptions.base_url + '/connect/user/'
        connect_user_req = StoreOptions.client.get(user_url)

        if connect_user_req.status_code == 200:
            # save user infos in session
            session["username"] = connect_user_req.json()["username"]
            session["email"] = connect_user_req.json()["email"]
            session["phone_number"] = connect_user_req.json()["phone_number"]
            session["first_name"] = connect_user_req.json()["first_name"]
            session["last_name"] = connect_user_req.json()["last_name"]
            session['logged_in'] = True
            session['guest'] = False

            
            if connect_user_req.json()["isconfirmed"]:
                # get wish list if user is connect
                from .utils import StoreUtils
                try:
                    StoreUtils.get_wishlist()
                except Exception as e:
                    session['logged_in'] = False
                    session['guest'] = True
                    session.pop('username', None)
                    session.pop('email', None)
                    session.pop('phone_number', None)
                    session.pop('first_name', None) 
                    session.pop('last_name', None)
                    return e    
        else:
            abort(500)

    @staticmethod
    def refresh_store_token(r_token):
        try:
            headers = {
                "content-type": "application/json",
                'User-Agent': f'flask/requests/{os.environ.get("BACKEND_VERSION")}',
            }

            data = {
                "client_id": os.environ.get('CLIENT_ID'),
                "client_secret": os.environ.get('CLIENT_SECRET'),
                "grant_type": "refresh_token",
                "refresh_token": r_token
            }
            fresh = requests.post(StoreConnect.token_url,
                                    data=json.dumps(data), headers=headers)

            fresh_data = fresh.json()
            if not 'error' in fresh_data:
                data = {
                    'access_token': fresh_data['access_token'],
                    'refresh_token': fresh_data['refresh_token']
                }
                with open('./Backend/token/data.txt', 'w') as outfile:
                    json.dump(data, outfile)
        except:
            print("error in refresh store token ")
    
    @ staticmethod
    def refresh_client_token(r_token):
        try:
            headers = {
                "content-type": "application/json",
                'User-Agent': f'flask/requests/{os.environ.get("BACKEND_VERSION")}',
            }
            data = {
                "client_id": os.environ.get('SUB_CLIENT_ID'),
                "client_secret": os.environ.get('SUB_CLIENT_SECRET'),
                "grant_type": "refresh_token",
                "refresh_token": r_token
            }

            fresh = requests.post(StoreConnect.token_url,
                                  data=json.dumps(data), headers=headers)

            fresh_data = fresh.json()

            if not 'error' in fresh_data:
                session["client_access_token"] = fresh_data["access_token"]
                session["client_refresh_token"] = fresh_data["refresh_token"]

        except:
            print("error in refresh client token")
