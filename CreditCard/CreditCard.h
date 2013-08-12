/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 * This file is part of CreditCard -- an iOS project that provides a smooth and elegant 
 * means to enter or edit credit cards. It was inspired by  a similar form created from 
 * scratch by Square (https://squareup.com/). To see this form in action visit:
 * 
 *   http://functionsource.com/post/beautiful-forms)
 *
 * Copyright 2012 Lot18 Holdings, Inc. All Rights Reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright notice, this list
 *       of conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY Lot18 Holdings ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL David Hoerl OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

typedef NS_ENUM(NSUInteger,CreditCardType)
{
    CreditCardTypeVisa,
    CreditCardTypeMasterCard,
    CreditCardTypeAMEX,
    CreditCardTypeDiscover,
    CreditCardTypeDinersClub,
    CreditCardTypeInvalid
};

#define CardTypeNameVisa @"Visa"
#define CardTypeNameMasterCard @"MasterCard"
#define CardTypeNameAmex @"Amex"
#define CardTypeNameDiscover @"Discover"
#define CardTypeNameDinersClub @"Diner's Club"

#define CC_MIN_LENGTH_TO_DETERMINE_CCTYPE	4	// number of characters to determine length

#define		kCCid				@"id"				// key for record (NSNumber)
#define		kCCnumber			@"card_number"		// key for obfuscated number (string)
#define		kCCtype				@"card_type"		// one of four strings: Master Card, CreditCardTypeVisa, American Express, Diners Club, and CreditCardTypeDiscover
#define		kCCexpir			@"card_expiration"	// key for expDate in YYYY-MM format (string)
#define		kCCccv				@"card_cvv"			// key for CCV (NSNumber)
#define		kCCaddrID			@"address_id"		// key for Address ID (NSNumber)
#define		kCCdefault			@"default"			// key for is this the default address (NSNumber bool)

#import "CreditCard.h"

@interface CreditCard : NSObject
@property (nonatomic, strong) NSDictionary *dictionary;

+ (CreditCardType)ccTypeWithCardNumber:(NSString *)proposedNumber;
/*!
@param number the unformatted card number
@return a formatted number with all but the last group obscured. Example for Visa: "Visa •••• •••• •••• 1234"
 */
+ (NSString *)obscuredCardWithNumber:(NSString *)cardNumber;
/*!
 
 */
+ (BOOL)isValidNumber:(NSString *)proposedNumber;
//+ (BOOL)isLuhnValid:(NSString *)proposedNumber;
+ (NSString *)formattedStringForCardNumber:(NSString *)enteredNumber;
//+ (NSString *)promptStringForType:(CreditCardType)type justNumber:(BOOL)justNumber;
//+ (NSString *)lastGroupForCardWithNumber:(NSString *)cardNumber;
+ (NSUInteger)lengthOfStringForType:(CreditCardType)type;
+ (NSUInteger)lengthOfFormattedStringForType:(CreditCardType)type;
+ (NSUInteger)lengthOfFormattedStringTillLastGroupForType:(CreditCardType)type;
+ (NSString *)ccvFormat:(CreditCardType)type;

@end
